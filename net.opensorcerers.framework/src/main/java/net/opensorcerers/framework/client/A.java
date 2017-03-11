package net.opensorcerers.framework.client;

import java.util.ArrayList;
import java.util.function.BiConsumer;

import com.google.gson.JsonArray;
import com.google.gwt.user.client.rpc.AsyncCallback;

public class A {
	static BiConsumer<JsonArray, AsyncCallback<JsonArray>>[] b = new BiConsumer[] {
			new BiConsumer<JsonArray, AsyncCallback<JsonArray>>() {
				@Override
				public void accept(JsonArray t, AsyncCallback<JsonArray> u) {
					// TODO Auto-generated method stub

				}
			} };

	void k() {
		B.a(this::z);
	}

	static {
		b[0] = null;
	}
	static {
		b[1] = null;
		AsyncCallback<JsonArray> z = null;
		callme(new AsyncCallback<ArrayList<String>>() {
			@Override
			public void onSuccess(ArrayList<String> r) {
				
			}
			
			@Override
			public void onFailure(Throwable caught) {
				z.onFailure(caught);
			}
		});
	}

	private int z(String k) {
		return 0;
	}

	static void callme(AsyncCallback<ArrayList<String>> callback) {

	}
}
