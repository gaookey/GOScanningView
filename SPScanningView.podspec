Pod::Spec.new do |spec|
 
  spec.name                   = 'SPScanningView'
  spec.version                = '0.0.12'
  spec.summary                = 'A simple scan and crop view.'
  spec.homepage               = 'https://github.com/swiftprimer/SPScanningView'
  spec.license                = { :type => 'MIT', :file => 'LICENSE' }
  spec.author                 = { '高文立' => 'swiftprimer@foxmail.com' }
  spec.platform               = :ios, "10.0"
  spec.source                 = { :git => "https://github.com/swiftprimer/SPScanningView.git", :tag => spec.version }
  spec.source_files           = "Classes/**/*"
  spec.swift_version          = '5.0'
 
 end

