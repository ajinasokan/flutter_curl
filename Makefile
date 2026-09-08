
clean:
	rm -rf ios/Curl.xcframework
	rm -rf macos/Curl.framework
	fvm flutter clean
	cd example; fvm flutter clean
	fvm flutter pub get

runArm:
	cd example; fvm flutter run -d macos

runx86:
	cd example; arch -x86_64 fvm flutter run -d macos
