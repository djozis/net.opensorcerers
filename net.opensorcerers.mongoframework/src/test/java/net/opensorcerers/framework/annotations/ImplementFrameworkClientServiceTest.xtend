package net.opensorcerers.framework.annotations

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class ImplementFrameworkClientServiceTest {
	extension XtendCompilerTester compiler = XtendCompilerTester.newXtendCompilerTester(class.classLoader)
	
	@Test def void testSimple() {
		'''
			package net.opensorcerers.game.client
			
			import com.google.gwt.user.client.rpc.AsyncCallback
			import java.util.ArrayList
			import net.opensorcerers.framework.annotations.ImplementFrameworkClientService
			
			@ImplementFrameworkClientService class TestCServiceImpl {
				override void testMessage(String x, AsyncCallback<ArrayList<String>> callback) {
					callback.onSuccess(new ArrayList<String> => [add("Hello from client: " + x)])
				}
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/xtend-gen/net/opensorcerers/game/client/TestCService.java
			
			package net.opensorcerers.game.client;
			
			import com.google.gwt.user.client.rpc.AsyncCallback;
			import java.util.ArrayList;
			
			@SuppressWarnings("all")
			public interface TestCService {
			  public abstract void testMessage(final String x, final AsyncCallback<ArrayList<String>> callback);
			}
			
			File 2 : /myProject/xtend-gen/net/opensorcerers/game/client/TestCServiceImpl.java
			
			package net.opensorcerers.game.client;
			
			import com.google.gwt.json.client.JSONArray;
			import com.google.gwt.json.client.JSONValue;
			import com.google.gwt.user.client.rpc.AsyncCallback;
			import java.util.ArrayList;
			import net.opensorcerers.framework.annotations.ImplementFrameworkClientService;
			import net.opensorcerers.framework.client.FrameworkClientServiceBase;
			import net.opensorcerers.game.client.TestCService;
			import org.eclipse.xtext.xbase.lib.ObjectExtensions;
			import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;
			import org.eclipse.xtext.xbase.lib.Procedures.Procedure3;
			
			@ImplementFrameworkClientService
			@SuppressWarnings("all")
			public class TestCServiceImpl extends FrameworkClientServiceBase implements TestCService {
			  private static class TestMessage__Consumer implements Procedure3<TestCServiceImpl, JSONArray, AsyncCallback<JSONValue>> {
			    public void apply(final TestCServiceImpl it, final JSONArray message, final AsyncCallback<JSONValue> resultCallback) {
			      com.google.gwt.json.client.JSONValue f;
			      f = message.get(1);
			      String x__value;
			      if (f == null || f.isNull() != null) {
			      	x__value = null;
			      } else {
			      	x__value = net.opensorcerers.framework.client.JsonSerializationClient.deserializeString(f);
			      }
			      it.testMessage(
			      	x__value,
			      	new AsyncCallback<ArrayList<String>>() {
			      		@Override public void onSuccess(ArrayList<String> r) {
			      			com.google.gwt.json.client.JSONValue serializedResult;
			      			if (r == null) {
			      				serializedResult = com.google.gwt.json.client.JSONNull.getInstance();
			      			} else
			      			serializedResult = net.opensorcerers.framework.client.JsonSerializationClient.serializeIterable(r, (java.lang.String it0) ->
			      				net.opensorcerers.framework.client.JsonSerializationClient.serialize(it0)
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
			  
			  public void testMessage(final String x, final AsyncCallback<ArrayList<String>> callback) {
			    ArrayList<String> _arrayList = new ArrayList<String>();
			    final Procedure1<ArrayList<String>> _function = new Procedure1<ArrayList<String>>() {
			      public void apply(final ArrayList<String> it) {
			        it.add(("Hello from client: " + x));
			      }
			    };
			    ArrayList<String> _doubleArrow = ObjectExtensions.<ArrayList<String>>operator_doubleArrow(_arrayList, _function);
			    callback.onSuccess(_doubleArrow);
			  }
			  
			  @Override
			  protected String getAddress() {
			    return "testCService";
			  }
			  
			  private final static Procedure3<TestCServiceImpl, JSONArray, AsyncCallback<JSONValue>>[] methodConsumers = new org.eclipse.xtext.xbase.lib.Procedures.Procedure3[] {
			    	new net.opensorcerers.game.client.TestCServiceImpl.TestMessage__Consumer()
			    };
			  
			  @Override
			  protected Procedure3<TestCServiceImpl, JSONArray, AsyncCallback<JSONValue>>[] getMethodConsumers() {
			    return methodConsumers;
			  }
			}
			
			File 3 : /myProject/xtend-gen/net/opensorcerers/game/server/TestCServiceProxy.java
			
			package net.opensorcerers.game.server;
			
			import com.google.gwt.user.client.rpc.AsyncCallback;
			import io.vertx.core.eventbus.EventBus;
			import java.util.ArrayList;
			import net.opensorcerers.framework.server.FrameworkClientServiceProxy;
			import net.opensorcerers.game.client.TestCService;
			
			@SuppressWarnings("all")
			public class TestCServiceProxy extends FrameworkClientServiceProxy implements TestCService {
			  @Override
			  protected String getAddress() {
			    return "testCService";
			  }
			  
			  public TestCServiceProxy(final EventBus eventBus, final String sessionId) {
			    super(eventBus, sessionId);
			  }
			  
			  public void testMessage(final String x, final AsyncCallback<ArrayList<String>> callback) {
			    com.google.gson.JsonArray message = new com.google.gson.JsonArray();
			    message.add(new com.google.gson.JsonPrimitive(0));
			    if (x == null) {
			    	message.add(com.google.gson.JsonNull.INSTANCE);
			    } else
			    message.add(net.opensorcerers.framework.server.JsonSerializationServer.serialize(x));
			    sendRequest(message,
			    	new com.google.gwt.user.client.rpc.AsyncCallback<com.google.gson.JsonElement>() {
			    		@Override public void onSuccess(com.google.gson.JsonElement r) {
			    			ArrayList<String> deserializedResult;
			    			if (r == null || r.isJsonNull()) {
			    				deserializedResult = null;
			    			} else {
			    				deserializedResult = net.opensorcerers.framework.server.JsonSerializationServer.deserializeIterable(r, (com.google.gson.JsonElement it0) ->
			    					net.opensorcerers.framework.server.JsonSerializationServer.deserializeString(it0),
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
			
		''')
	}
}
