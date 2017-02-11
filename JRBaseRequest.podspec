Pod::Spec.new do |s|

    s.name                  = "JRBaseRequest"
    s.version="1.1.0"
    s.summary               = "A network request protocol, its design to work for other network lib"

    s.homepage              = "https://github.com/scubers"
    s.license               = { :type => "MIT", :file => "LICENSE" }

    s.author                = { "jrwong" => "jr-wong@qq.com" }
    s.ios.deployment_target = "8.0"
    s.source                = { :git => "https://github.com/scubers/JRBaseRequest.git", :tag => "#{s.version}" }


    s.source_files          = "JRBaseRequest/classes/**/*.{h,m}"
    s.public_header_files   = "JRBaseRequest/classes/**/*.h"

end
