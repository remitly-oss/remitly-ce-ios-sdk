Pod::Spec.new do |s|
    s.name         = "RemitlyCEKit"
    s.version      = "0.1.3"
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.homepage     = "https://github.com/Remitly/remitly-ce-ios-sdk"
    s.authors      = { 'Nick Hodapp' => 'nick@remitly.com' }
    s.summary      = "Remitly Connected Experiences SDK for iOS.   Send money with Remitly within your application."
    s.source       =  { :git => "https://github.com/Remitly/remitly-ce-ios-sdk.git", 
                        :branch => "CP-270" }
    s.platform     = :ios, "13.0"
    s.swift_version = "5"
    s.source_files = 'RemitlyCEKit/*.{h,m,swift}'
    s.resources = ['RemitlyCEKit/*.{xib}']
    s.ios.frameworks = 'WebKit', 'SafariServices'
    s.pod_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => 'RemitlyCE_VERSION=' + s.version.to_s
    }
    s.dependency 'AnyCodable-FlightSchool', '~> 0.6.0'
end