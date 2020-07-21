Pod::Spec.new do |spec|
 
  spec.name                   = 'SPScanningView'
  spec.version                = '0.0.8'
  spec.summary                = 'A simple scan and crop view.'
  spec.homepage               = 'https://mouos.com'
  spec.license                = { :type => 'MIT', :file => 'LICENSE' }
  spec.author                 = { '高文立' => 'swiftprimer@gmail.com' }
  spec.platform               = :ios, "11.0"
  spec.source                 = { :git => "https://github.com/mouos/SPScanningView.git", :tag => spec.version }
  spec.source_files           = "Classes/**/*"
  spec.swift_version          = '5.0'
 
 end

