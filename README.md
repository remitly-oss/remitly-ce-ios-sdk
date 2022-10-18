<img src=".github/Remitly_Horizontal_Logo_Preferred_RGB_Indigo_192x44.png" title="Remitly Logo" />

# Remitly Connected Experiences SDK for iOS

## Requirements

- RemitlyCE supports iOS 13.0 or newer
- Xcode 13.2.1 (13C100) or newer
- CocoaPods package manager

## Examples

The RemitlyCE SDK Examples project showcases different RemitlyCE integrations in both Swift and Objective C.   

- Navigate to the `Examples` directory
- Run `pod install`
- Open `Examples-CocoaPods.xcworkspace`

## Integration

RemitlyCE can be added to your app with as little as two lines of code.   

```
    RemitlyCeConfiguration.loadConfig()
    RemitlyCeViewController.present()
```

### Configuration

At minimum, RemitlyCE needs to be configured with your assigned `AppID` and `webEndpoint` values.   These can be configured in code or provided in your app's `Info.plist` (recommended):

```
    <key>remitly</key>
    <dict>
        <key>appID</key>
        <string>YOUR_APP_ID_HERE</string>
        <key>webEndpoint</key>
        <string>YOUR_WEB_ENDPOINT_URL_HERE</string>
    </dict>
```

Then, in code prior to invoking the RemitlyCE UI:

```
    RemitlyCeConfiguration.loadConfig()
```

Alternatively, configuration values may be set in code:

```
    RemitlyCeConfiguration.defaultSendCountry = "USA"
    RemitlyCeConfiguration.defaultReceiveCountry = "PHL"
    RemitlyCeConfiguration.customerEmail = "nick+0618@remitly.com"
    RemitlyCeConfiguration.languageCode = "en"
```


| Property              | Description                                                              | Type   | Required | Default Value                 | Access     |
|-----------------------|--------------------------------------------------------------------------|--------|----------|-------------------------------|------------|
| appID                 | Provided by Remitly                                                      | string | [x]      |                               | read/write |
| webEndpoint           | Provided by Remitly                                                      | string | [x]      |                               | read/write |
| apiEndpoint           | Provided by Remitly                                                      | string | [ ]      |                               | read/write |
| defaultSendCountry    | 3-letter ISO country code                                                | string | [ ]      | USA                           | read/write |
| defaultReceiveCountry | 3-letter ISO country code                                                | string | [ ]      | PHL                           | read/write |
| customerEmail         | Will prepopulate the end-user login screen                               | string | [ ]      |                               | read/write |
| languageCode          | 2-letter ISO language code.   Unsupported languages fallback to English. | string | [ ]      | `Locale.current.languageCode` | read/write |
| ceVersion             | The SDK version in form `major.minor.revision`                           | string | [ ]      |                               | readonly   |


### Presentation

The RemitlyCE SDK vends a `RemitlyCeViewController` (Swift) / `RECEViewController` (ObjC) view controller that contains the entierty of the Remitly CE UI.   You must instantiate and present this view controller modally in your app at the desired point of integration.   This can be done in code or via a Storyboard segue, as demonstrated in the provided Example project.

Do NOT push the `RemitlyCeViewController` to a `UINavigationController` stack.   While this will appear to work the user experience will be sub-par.  RemitlyCE is designed to be presented modally in full-screen or page-sheet form. 

#### Swift

```
    let remitlyCe = RemitlyCeViewController()

    self.present(remitlyCe, animated: true, completion: nil)  // where `self` is an on-screen view controller
```

#### Objective C

```
    RECEViewController* receVc = [RECEViewController new];
    [self presentViewController: receVc animated: YES completion: nil];  // where `self` is an on-screen view controller

```


Alternatively, the RemitlyCE UI can be presented from anywhere using a provided helper method:

#### Swift

```
    RemitlyCeViewController.present()
```

#### Objective C

```
    [RECEViewController present];
```

### Events

The RemitlyCeViewController optionally notifies an associated delegate of certain events that occur in the RemitlyCE experience.   To receive these events, implement the desired methods on a delegate and provide that to the RemitlyCeViewController instance.

| Event                  | Description                                                         |
|------------------------|---------------------------------------------------------------------|
| onUserActivity         | Triggered frequently as the user interacts with the RemitlyCE UI.   |
| onTransactionSubmitted | Triggered when the user successfully submits a transaction request. |




