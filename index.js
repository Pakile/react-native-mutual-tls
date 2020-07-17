import { NativeModules, NativeEventEmitter } from "react-native";

const MutualTLS = {
  native: NativeModules.MutualTLS,
  onDebug: null, // place a function here to receive debug messages
  onError: null, // place a function here to receive error messages
};

const { configure } = NativeModules.MutualTLS;

const debug = new NativeEventEmitter(NativeModules.MutualTLSDebug);
var debugSubscription = null;
export function onDebug(fn) {
  if (debugSubscription) debug.removeSubscription(debugSubscription);
  debugSubscription = fn
    ? debug.addListener("MutualTLSDebug", (a) => fn(...a))
    : null;
}

const error = new NativeEventEmitter(NativeModules.MutualTLSError);
var errorSubscription = null;
export function onError(fn) {
  if (errorSubscription) error.removeSubscription(errorSubscription);
  errorSubscription = fn
    ? error.addListener("MutualTLSError", (a) => fn(...a))
    : null;
}

export default {
  configure,
  onDebug,
  onError,
};
