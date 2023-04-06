
clean:
	rm -rf ios/Curl.xcframework
	rm -rf macos/Curl.framework
	flutter clean
	cd example; flutter clean
	flutter pub get

runArm:
	cd example; flutter run -d macos

runx86:
	cd example; arch -x86_64 flutter run -d macos

setup-maven:
	rm -rf android/maven
	mkdir -p android/maven
	cd android/maven; mvn install:install-file -DgroupId=com.ajinasokan -DartifactId=flutter_curl -Dversion=0.0.1 -Dfile=../../curl.aar -Dpackaging=aar -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true
	mv android/maven/com/ajinasokan/flutter_curl/maven-metadata-local.xml android/maven/com/ajinasokan/flutter_curl/maven-metadata.xml
	mv android/maven/com/ajinasokan/flutter_curl/maven-metadata-local.xml.md5 android/maven/com/ajinasokan/flutter_curl/maven-metadata.xml.md5
	mv android/maven/com/ajinasokan/flutter_curl/maven-metadata-local.xml.sha1 android/maven/com/ajinasokan/flutter_curl/maven-metadata.xml.sha1
	rm android/maven/com/ajinasokan/flutter_curl/0.0.1/flutter_curl-0.0.1.aar