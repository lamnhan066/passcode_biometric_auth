## 0.1.0-rc

* **BREAKING CHANGE:**  
The behavior of `onRead` and `onWrite` in `PasscodeBiometricAuthUI` has been updated. The `key` now correctly incorporates the `prefix`. If you need to maintain the previous behavior, remove the `prefix` from your key as follows:

    ```dart
    final oldKey = newKey.substring(prefix.length + 1);
    ```

* Introduced a new `salt` parameter for enhanced security.
* Added `PasscodeBiometricAuth.generateSalt()` to generate unique salt values.
* Provided `PasscodeBiometricAuth.sha256FromPasscode(String code, String salt)` to compute a secure SHA256 hash from the passcode and salt.
* Made `PasscodeBiometricAuth` const constructible.
* The `CreatePasscode` dialog will be dismissed before the `RepeatPasscode` dialog is presented.
* Refactored internal code to boost performance.
* Improved code comments for better clarity.

## 0.0.3

* Update dependencies.
* Update README.
* Update example.

## 0.0.2+3

* Update dialog configs.

## 0.0.1

* Initial release
