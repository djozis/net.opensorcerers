package net.opensorcerers.framework.annotations

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class ImplementStaticJsonSerializationTest {
	extension XtendCompilerTester compiler = XtendCompilerTester.newXtendCompilerTester(class.classLoader)
	
	@Test def void testSimple() {
		'''
			package net.opensorcerers.game.shared
			
			import java.util.ArrayList
			import java.util.HashSet
			import net.opensorcerers.framework.annotations.ImplementStaticJsonSerialization
			
			@ImplementStaticJsonSerialization class TestPOJO {
				String a
				int b
			}
		'''.assertCompilesTo('''
			package net.opensorcerers.game.shared;
			
			import com.google.gson.JsonElement;
			import com.google.gwt.core.shared.GwtIncompatible;
			import com.google.gwt.json.client.JSONValue;
			import net.opensorcerers.framework.annotations.ImplementStaticJsonSerialization;
			import net.opensorcerers.framework.shared.StaticallyJsonSerializable;
			import org.eclipse.xtext.xbase.lib.Pure;
			
			@ImplementStaticJsonSerialization
			@SuppressWarnings("all")
			public class TestPOJO implements StaticallyJsonSerializable {
			  private String a;
			  
			  private int b;
			  
			  @Override
			  @Pure
			  public JSONValue serializeToJsonClient() {
			    com.google.gwt.json.client.JSONArray v = new com.google.gwt.json.client.JSONArray();
			    if (this.a == null) {
			    	v.set(0, com.google.gwt.json.client.JSONNull.getInstance());
			    } else
			    v.set(0, net.opensorcerers.framework.client.JsonSerializationClient.serialize(this.a));
			    v.set(1, net.opensorcerers.framework.client.JsonSerializationClient.serialize(this.b));
			    return v;
			  }
			  
			  @Override
			  public TestPOJO deserializeFromJsonClient(final JSONValue jsonValue) {
			    com.google.gwt.json.client.JSONArray v = jsonValue.isArray();
			    if (v == null) {
			    	throw new java.lang.IllegalArgumentException(
			    		"net.opensorcerers.game.shared.TestPOJO.deserializeFromJsonClient received a JSONValue that was not a JSONArray."
			    	);
			    }
			    com.google.gwt.json.client.JSONValue f;
			    f = v.get(0);
			    if (f == null || f.isNull() != null) {
			    	this.a = null;
			    } else {
			    	this.a = net.opensorcerers.framework.client.JsonSerializationClient.deserializeString(f);
			    }
			    f = v.get(1);
			    if (f == null || f.isNull() != null) {
			    	throw new java.lang.NullPointerException(
			    		"net.opensorcerers.game.shared.TestPOJO.deserializeFromJsonClient received a null JSONValue for primitive field b."
			    	);
			    } else {
			    	this.b = net.opensorcerers.framework.client.JsonSerializationClient.deserializeint(f);
			    }
			    return this;
			  }
			  
			  @GwtIncompatible
			  @Pure
			  public JsonElement serializeToJsonServer() {
			    com.google.gson.JsonArray v = new com.google.gson.JsonArray();
			    if (this.a == null) {
			    	v.add(com.google.gson.JsonNull.INSTANCE);
			    } else
			    v.add(net.opensorcerers.framework.server.JsonSerializationServer.serialize(this.a));
			    v.add(net.opensorcerers.framework.server.JsonSerializationServer.serialize(this.b));
			    return v;
			  }
			  
			  @GwtIncompatible
			  public TestPOJO deserializeFromJsonServer(final JsonElement jsonElement) {
			    if (!jsonElement.isJsonArray()) {
			    	throw new java.lang.IllegalArgumentException(
			    		"net.opensorcerers.game.shared.TestPOJO.deserializeFromJsonServer received a JsonElement that was not a JsonArray."
			    	);
			    }
			    com.google.gson.JsonArray v = jsonElement.getAsJsonArray();
			    com.google.gson.JsonElement f;
			    f = v.get(0);
			    if (f == null || f.isJsonNull()) {
			    	this.a = null;
			    } else {
			    	this.a = net.opensorcerers.framework.server.JsonSerializationServer.deserializeString(f);
			    }
			    f = v.get(1);
			    if (f == null || f.isJsonNull()) {
			    	throw new java.lang.NullPointerException(
			    		"net.opensorcerers.game.shared.TestPOJO.deserializeFromJsonServer received a null JsonElement for primitive field b."
			    	);
			    } else {
			    	this.b = net.opensorcerers.framework.server.JsonSerializationServer.deserializeint(f);
			    }
			    return this;
			  }
			}
		''')
	}
}
