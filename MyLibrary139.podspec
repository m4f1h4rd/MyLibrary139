Pod::Spec.new do |s|

  s.name             = 'MyLibrary139'
  s.version          = '1.0.0'
  s.summary          = 'A short description of MyLibrary139.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/OleksandrLan/MyLibrary139'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'OleksandrLan' => 'oleksandr@lanars.com' }
  s.source           = { :git => 'https://github.com/OleksandrLan/MyLibrary139.git', :tag => s.version.to_s }
  s.source_files     = 'MyLibrary139/Classes/**/*'
  s.exclude_files    = 'MyLibrary139/Support Files/*.plist'
  s.frameworks            = 'UIKit'
  s.ios.deployment_target = '10.0'
  s.swift_version         = '5.0'

end
