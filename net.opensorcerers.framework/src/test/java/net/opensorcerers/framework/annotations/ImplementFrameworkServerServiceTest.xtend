package net.opensorcerers.framework.annotations

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class ImplementFrameworkServerServiceTest {
	extension XtendCompilerTester compiler = XtendCompilerTester.newXtendCompilerTester(class.classLoader)
	
	@Test def void testSimple() {
		'''
			package net.opensorcerers.game.server
			
			import com.google.gwt.user.client.rpc.AsyncCallback
			import java.util.ArrayList
			import net.opensorcerers.framework.annotations.ImplementFrameworkServerService
			
			@ImplementFrameworkServerService class TestClassImpl {
				override void sayHello(String x, AsyncCallback<ArrayList<String>> callback) {
					callback.onSuccess(new ArrayList<String> => [add("Hello: " + x)])
				}
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/xtend-gen/net/opensorcerers/game/client/TestClassProxy.java
			
			package net.opensorcerers.game.client;
			
			import com.google.gwt.user.client.rpc.AsyncCallback;
			import java.util.ArrayList;
			import net.opensorcerers.framework.client.FrameworkServerServiceProxy;
			import net.opensorcerers.framework.client.vertx.VertxEventBus;
			import net.opensorcerers.game.shared.TestClass;
			
			@SuppressWarnings("all")
			public class TestClassProxy extends FrameworkServerServiceProxy implements TestClass {
			  @Override
			  protected String getAddress() {
			    return "testClass";
			  }
			  
			  public TestClassProxy(final VertxEventBus eventBus) {
			    super(eventBus);
			  }
			  
			  public void sayHello(final String x, final AsyncCallback<ArrayList<String>> callback) {
			    com.google.gwt.json.client.JSONArray message = new com.google.gwt.json.client.JSONArray();
			    message.set(0, new com.google.gwt.json.client.JSONNumber(0));
			    if (x == null) {
			    	message.set(1, com.google.gwt.json.client.JSONNull.getInstance());
			    } else
			    message.set(1, net.opensorcerers.framework.client.JsonSerializationClient.serialize(x));
			    sendRequest(message,
			    	new com.google.gwt.user.client.rpc.AsyncCallback<com.google.gwt.json.client.JSONValue>() {
			    		@Override public void onSuccess(com.google.gwt.json.client.JSONValue r) {
			    			ArrayList<String> deserializedResult;
			    			if (r == null || r.isNull() != null) {
			    				deserializedResult = null;
			    			} else {
			    				deserializedResult = net.opensorcerers.framework.client.JsonSerializationClient.deserializeIterable(r, (com.google.gwt.json.client.JSONValue it0) ->
			    					net.opensorcerers.framework.client.JsonSerializationClient.deserializeString(it0),
			    				new java.util.ArrayList<java.lang.String>());
			    			}
			    			callback.onSuccess(deserializedResult);
			    		}
			    		
			    		@Override public void onFailure(Throwable caught) {
			    			callback.onFailure(caught);
			    		}
			    	}
			    );
			  }
			}
			
			File 2 : /myProject/xtend-gen/net/opensorcerers/game/server/TestClassImpl.java
			
			package net.opensorcerers.game.server;
			
			import com.google.gson.JsonArray;
			import com.google.gson.JsonElement;
			import com.google.gwt.user.client.rpc.AsyncCallback;
			import java.util.ArrayList;
			import net.opensorcerers.framework.annotations.ImplementFrameworkServerService;
			import net.opensorcerers.framework.server.FrameworkServerServiceBase;
			import net.opensorcerers.game.shared.TestClass;
			import org.eclipse.xtext.xbase.lib.ObjectExtensions;
			import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;
			import org.eclipse.xtext.xbase.lib.Procedures.Procedure3;
			
			@ImplementFrameworkServerService
			@SuppressWarnings("all")
			public class TestClassImpl extends FrameworkServerServiceBase implements TestClass {
			  private static class SayHello__Consumer implements Procedure3<TestClassImpl, JsonArray, AsyncCallback<JsonElement>> {
			    public void apply(final TestClassImpl it, final JsonArray message, final AsyncCallback<JsonElement> resultCallback) {
			      com.google.gson.JsonElement f;
			      f = message.get(1);
			      String x__value;
			      if (f == null || f.isJsonNull()) {
			      	x__value = null;
			      } else {
			      	x__value = net.opensorcerers.framework.server.JsonSerializationServer.deserializeString(f);
			      }
			      it.sayHello(
			      	x__value,
			      	new AsyncCallback<ArrayList<String>>() {
			      		@Override public void onSuccess(ArrayList<String> r) {
			      			com.google.gson.JsonElement serializedResult;
			      			if (r == null) {
			      				serializedResult = com.google.gson.JsonNull.INSTANCE;
			      			} else
			      			serializedResult = net.opensorcerers.framework.server.JsonSerializationServer.serializeIterable(r, (java.lang.String it0) ->
			      				net.opensorcerers.framework.server.JsonSerializationServer.serialize(it0)
			      			);
			      			resultCallback.onSuccess(serializedResult);
			      		}
			      		
			      		@Override public void onFailure(Throwable caught) {
			      			resultCallback.onFailure(caught);
			      		}
			      	}
			      );
			    }
			  }
			  
			  public void sayHello(final String x, final AsyncCallback<ArrayList<String>> callback) {
			    ArrayList<String> _arrayList = new ArrayList<String>();
			    final Procedure1<ArrayList<String>> _function = new Procedure1<ArrayList<String>>() {
			      public void apply(final ArrayList<String> it) {
			        it.add(("Hello: " + x));
			      }
			    };
			    ArrayList<String> _doubleArrow = ObjectExtensions.<ArrayList<String>>operator_doubleArrow(_arrayList, _function);
			    callback.onSuccess(_doubleArrow);
			  }
			  
			  @Override
			  protected String getAddress() {
			    return "testClass";
			  }
			  
			  private final static Procedure3<TestClassImpl, JsonArray, AsyncCallback<JsonElement>>[] methodConsumers = new org.eclipse.xtext.xbase.lib.Procedures.Procedure3[] {
			    	new net.opensorcerers.game.server.TestClassImpl.SayHello__Consumer()
			    };
			  
			  @Override
			  protected Procedure3<TestClassImpl, JsonArray, AsyncCallback<JsonElement>>[] getMethodConsumers() {
			    return methodConsumers;
			  }
			}
			
			File 3 : /myProject/xtend-gen/net/opensorcerers/game/shared/TestClass.java
			
			package net.opensorcerers.game.shared;
			
			import com.google.gwt.user.client.rpc.AsyncCallback;
			import java.util.ArrayList;
			
			@SuppressWarnings("all")
			public interface TestClass {
			  public abstract void sayHello(final String x, final AsyncCallback<ArrayList<String>> callback);
			}
			
		''')
	}
}
