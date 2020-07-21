Pod::Spec.new do |s|

  s.name                   = 'SPScanningView'
  s.version                = '0.0.2'
  s.summary                = 'A simple scan and crop view.'
  s.homepage               = 'https://mouos.com'
  s.license                = { :type => 'MIT', :file => 'LICENSE' }
  s.author                 = { '高文立' => 'swiftprimer@gmail.com' }
  s.platform               = :ios, "11.0"
  s.source                 = { :git => "https://github.com/mouos/SPScanningView.git", :tag => s.version }
  s.source_files           = "Classes/**/*"
  s.swift_version          = '5.0'

end
