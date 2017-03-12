package net.opensorcerers.coverage

import com.google.gson.JsonParser
import com.google.gwt.dev.js.CoverageInstrumentor
import java.io.File
import java.io.FileOutputStream
import java.util.ArrayList
import java.util.HashMap
import net.opensorcerers.util.ReflectionsBootstrap
import org.apache.commons.io.IOUtils
import org.jacoco.core.data.ExecutionData
import org.jacoco.core.data.ExecutionDataWriter
import org.jacoco.core.internal.data.CRC64
import org.jacoco.core.internal.flow.ClassProbesAdapter
import org.jacoco.core.internal.flow.ClassProbesVisitor
import org.jacoco.core.internal.flow.IFrame
import org.jacoco.core.internal.flow.LabelInfo
import org.jacoco.core.internal.flow.MethodProbesVisitor
import org.objectweb.asm.ClassReader
import org.objectweb.asm.Label
import org.objectweb.asm.Opcodes
import org.reflections.Reflections
import org.reflections.scanners.ResourcesScanner
import org.reflections.scanners.SubTypesScanner

class GWTJacocoAdaptor {
	static val classPackage = "net.opensorcerers"
	static val javaToJavaDataMap = try {
		createJavaToClassesMap
	} catch (Throwable e) {
		e.printStackTrace
		throw e
	}

	protected static class JavaData {
		val classDatas = new ArrayList<ClassData>
		boolean[] isGarbageLineStore

		def isLineGarbage(int lineNumber) {
			// Line numbers are 1-based!
			val zeroBased = lineNumber - 1
			return zeroBased >= 0 && zeroBased < isGarbageLineStore.length && isGarbageLineStore.get(zeroBased)
		}
	}

	protected static class ClassData {
		String classFilePath
		String javaFilePath
		ClassReader classReader
		long id
		boolean[] probes
	}

	def static void processCoverage(String gwtCoverageJsonString) {
		if (gwtCoverageJsonString !== null) {
			for (classCoverageEntry : new JsonParser().parse(gwtCoverageJsonString).asJsonObject.entrySet) {
				val javaFilePath = classCoverageEntry.key // eg: "net/opensorcerers/game/client/WebappTest.java"
				val isLineCovered = classCoverageEntry.value.asJsonObject // eg: {"129":1,"130":1,"131":1,"134":0,"27":1}
				val javaData = javaToJavaDataMap.get(javaFilePath)
				for (classData : javaData.classDatas) {
					classData.classReader.accept(new ClassProbesAdapter(new ClassProbesVisitor {
						override visitMethod(int access, String name, String desc, String signature,
							String[] exceptions) {
							return new MethodProbesVisitor {
								var firstLineOfMethod = -1
								var currentLineNumber = 0

								def confirmProbe(int probeId) { classData.probes.set(probeId, true) }

								def getGwtLineCovered(int lineNumber) {
									val isCurrentLineCovered = isLineCovered.getAsJsonPrimitive(
										lineNumber.toString
									)
									return isCurrentLineCovered !== null && isCurrentLineCovered.asInt != 0
								}

								def checkUpToNonGarbageLine(int lineNumber) {
									var lineNumberMutable = lineNumber - 1
									do {
										if (lineNumberMutable.gwtLineCovered) {
											return true
										}
									} while (javaData.isLineGarbage(lineNumberMutable--))
									return false
								}

								def checkDownToNonGarbageLine(int lineNumber) {
									var lineNumberMutable = lineNumber + 1
									do {
										if (lineNumberMutable.gwtLineCovered) {
											return true
										}
									} while (javaData.isLineGarbage(lineNumberMutable++))
									return false
								}

								override void visitLineNumber(int line, Label start) {
									currentLineNumber = line
									if (firstLineOfMethod == -1) {
										firstLineOfMethod = line
									}
								}

								override void visitProbe(int probeId) {
									var hit = currentLineNumber.gwtLineCovered
									// A constructor's first line is the declaration itself
									if (!hit && name == "<init>" && currentLineNumber == firstLineOfMethod) {
										// This is not perfect in theory, since an empty constructor will
										// check until the next constructor/method declaration.
										// However, the next constructor declaration will not have
										// been marked executed by GWT, and the next method, if called,
										// means the constructor must've been called.
										// The exception is declaring empty constructors after non-empty ones
										// which don't call the empty one. Oh well.
										hit = currentLineNumber.checkDownToNonGarbageLine
									}
									if(hit) probeId.confirmProbe
								}

								override void visitJumpInsnWithProbe(int opcode, Label label, int probeId,
									IFrame frame) {
									if(currentLineNumber.gwtLineCovered) probeId.confirmProbe
								}

								override void visitInsnWithProbe(int opcode, int probeId) {
									var hit = currentLineNumber.gwtLineCovered
									// This may not be perfect, but sometimes this is the only probe in a method.
									if (!hit && opcode == Opcodes.RETURN) {
										hit = currentLineNumber.checkUpToNonGarbageLine
									}
									if(hit) probeId.confirmProbe
								}

								override void visitTableSwitchInsnWithProbes(int min, int max, Label dflt,
									Label[] labels, IFrame frame) {
									for (label : labels) {
										val probeId = LabelInfo.getProbeId(label)
										if (probeId != LabelInfo.NO_PROBE && currentLineNumber.gwtLineCovered) {
											probeId.confirmProbe
										}
									}
								}

								override void visitLookupSwitchInsnWithProbes(Label dflt, int[] keys, Label[] labels,
									IFrame frame) {
									for (label : labels) {
										val probeId = LabelInfo.getProbeId(label)
										if (probeId != LabelInfo.NO_PROBE && currentLineNumber.gwtLineCovered) {
											probeId.confirmProbe
										}
									}
								}
							}
						}

						override visitTotalProbeCount(int count) {}
					}, false), ClassReader.EXPAND_FRAMES)
				}
			}
		}
	}

	/**
	 * Call this in runTest method of unit tests.
	 */
	def static setGwtCoveragePaths() {
		if (javaToJavaDataMap.empty) {
			throw new IllegalStateException(
				'''Couldn't find Java source files. When executing tests in Eclipse, make sure to use GWT JUnit Test run configuration type.'''
			)
		}
		System.setProperty(
			CoverageInstrumentor.GWT_COVERAGE_SYSTEM_PROPERTY,
			GWTJacocoAdaptor.javaToJavaDataMap.keySet.join(",")
		)
	}

	protected def static createJavaToClassesMap() {
		ReflectionsBootstrap.checkBootstrap
		val javasAndClasses = new Reflections(
			classPackage,
			ReflectionsBootstrap.urls,
			new ResourcesScanner,
			new SubTypesScanner
		).getResources[endsWith(".java") || endsWith(".class")]

		val javaToJavaDataMap = new HashMap<String, JavaData>
		for (javaFilePath : javasAndClasses.filter[endsWith(".java")]) {
			val javaData = new JavaData
			val javaLines = IOUtils.readLines(GWTJacocoAdaptor.classLoader.getResourceAsStream(javaFilePath))
			javaData.isGarbageLineStore = newBooleanArrayOfSize(javaLines.length)
			for (var i = javaLines.length - 1; i >= 0; i--) {
				val trimmedLine = javaLines.get(i).trim
				javaData.isGarbageLineStore.set(i, trimmedLine == "" || trimmedLine == "}" || trimmedLine == "};")
			}
			GWTJacocoAdaptor.classLoader.getResourceAsStream(javaFilePath)
			javaToJavaDataMap.put(javaFilePath, javaData)
		}

		for (classFile : javasAndClasses.filter[endsWith(".class")]) {
			var wheresTheMoney = classFile.indexOf("$")
			if (wheresTheMoney == -1) {
				wheresTheMoney = classFile.length - 6 // ".class".length
			}
			val javaFile = classFile.substring(0, wheresTheMoney) + ".java"
			val javaData = javaToJavaDataMap.get(javaFile)
			if (javaData !== null) {
				javaData.classDatas.add(
					new ClassData => [
						val classBytes = IOUtils.toByteArray(
							GWTJacocoAdaptor.classLoader.getResourceAsStream(classFile))
						it.classFilePath = classFile
						it.javaFilePath = javaFile
						it.classReader = new ClassReader(classBytes)
						it.id = CRC64.checksum(classBytes)
						classReader.accept(new ClassProbesAdapter(new ClassProbesVisitor {
							override visitMethod(int access, String name, String desc, String signature,
								String[] exceptions) {
								return new MethodProbesVisitor {
								}
							}

							override visitTotalProbeCount(int count) { it.probes = newBooleanArrayOfSize(count) }
						}, false), ClassReader.EXPAND_FRAMES)
					]
				)
			}
		}

		val fileOutputStream = new FileOutputStream(
			new File(
				new File('''build/«GWTJacocoAdaptor.simpleName»''') => [mkdirs],
				"jacoco.exec"
			)
		)
		val executionDataWriter = new ExecutionDataWriter(fileOutputStream)
		Runtime.runtime.addShutdownHook(new Thread [
			for (classData : javaToJavaDataMap.values.map[classDatas].flatten) {
				executionDataWriter.visitClassExecution(
					new ExecutionData(
						classData.id,
						classData.javaFilePath.substring(0, classData.javaFilePath.length - 5), // remove ".java"
						classData.probes
					)
				)
			}
			fileOutputStream.flush
			fileOutputStream.close
		])

		return javaToJavaDataMap
	}
}
