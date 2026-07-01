# DNSChat

Send messages to other devices on the local network.

## Usage

1. Download and install the latest release from https://github.com/tock-dev/dnschat/releases
2. Run the app on 2 devices
3. Press the settings icon in top-right and enter different usernames on both devices
4. Press the search icon in bottom-right on one of the devices. You should see the other device appear in the list
5. Press on the other device to connect to it
6. Send messages to each other

## Building

1. Clone the repository:

```bash
mkdir -p ~/Development
cd ~/Development
git clone https://github.com/tock-dev/dnschat.git
cd dnschat
```

2. Download and install the latest Flutter version following [these instructions](https://docs.flutter.dev/install/quick).
3. Follow [official documentation](https://docs.flutter.dev/platform-integration) to setup & build for your taget platform.

For example, to build for Android after setting up Android Studio:

```bash
flutter build apk
```
