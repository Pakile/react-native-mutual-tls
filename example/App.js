/**
 * Sample React Native App
 *
 * adapted from App.js generated by the following command:
 *
 * react-native init example
 *
 * https://github.com/facebook/react-native
 */

import React, {useState, useEffect} from 'react';
import {StyleSheet, Text, View} from 'react-native';
import RNFetchBlob from 'rn-fetch-blob';
import Keychain from 'react-native-keychain';
import MutualTLS from 'react-native-mutual-tls';

// Download a p12 client certificate file from badssl.com, for testing.
async function storeP12Data(service) {
  const response = await RNFetchBlob.fetch(
    'GET',
    'https://badssl.com/certs/badssl.com-client.p12',
  );
  const data = response.base64();

  await Keychain.setGenericPassword('', data, {service});
}

// Store the hard-coded password for the badssl.com test certificate file.
async function storePassword(service) {
  const password = 'badssl.com';

  await Keychain.setGenericPassword('', password, {service});
}

// Demonstrate how to set up mutual auth credentials and fetch. using them.
async function fullExample() {
  // Set up debug and error logging to the console.
  // These events come asynchronously during request handling.
  MutualTLS.onDebug(console.debug);
  MutualTLS.onError(console.error);
  await MutualTLS.configure({
    keychainServiceForP12: 'my-tls.client.p12',
    keychainServiceForPassword: 'my-tls.client.p12.password',
  });

  // Clear out any old/existing secrets, for testing accuracy.
  await Promise.all([
    Keychain.resetGenericPassword({service: 'my-tls.client.p12'}),
    Keychain.resetGenericPassword({
      service: 'my-tls.client.p12.password',
    }),
  ]);

  // Store the secrets we'll use in the keychain.
  await Promise.all([
    storeP12Data('my-tls.client.p12'),
    storePassword('my-tls.client.p12.password'),
  ]);

  // Perform a request to a server that requires the certificate.
  const response = await fetch('https://client.badssl.com/');
  if (response.status >= 300)
    console.error(`${response.status}`, await response.text());
  else console.log(`Request completed: ${response.status}`);

  return response;
}

export default function App() {
  const [response, setResponse] = useState(null);
  const [timestamp, setTimestamp] = useState(null);

  const backgroundColor = response
    ? response.status < 300
      ? 'green'
      : 'red'
    : 'white';

  useEffect(() => {
    var cancelled = false;

    fullExample()
      .then((response) => {
        if (cancelled) return;
        setResponse(response);
        setTimestamp(new Date().toLocaleTimeString());
      })
      .catch(console.error);

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <View style={[styles.container, {backgroundColor}]}>
      <Text style={styles.welcome}>???MutualTLS example???</Text>
      <Text style={styles.instructions}>
        RESPONSE CODE: {response ? response.status : 'NONE YET'}
      </Text>
      <Text style={styles.instructions}>LAST TIMESTAMP: {timestamp}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});
