package net.opensorcerers.framework.client

import com.google.gwt.json.client.JSONArray
import com.google.gwt.user.client.rpc.AsyncCallback
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3
import com.google.gwt.json.client.JSONValue

class TTT extends FrameworkClientServiceBase {
	override protected getAddress() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override protected Procedure3<TTT, JSONArray, AsyncCallback<JSONValue>>[]  getMethodConsumers() {
		var Procedure3<TTT, JSONArray, AsyncCallback<JSONValue>> k = null
		return #[k]
	}
}
