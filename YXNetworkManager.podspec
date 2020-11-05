
Pod::Spec.new do |s|
  s.name         = "YXNetworkManager"
  s.version      = "0.0.2"
  s.summary      = "提示框"
  s.description  = <<-DESC
                    YXNetworkManager 是使用AFNetworking、YYCache、YYModel的再封装，只为使用更简单
                   DESC
  s.homepage     = "https://github.com/charlesYun/YXNetworkManager"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Matej caoyunxiao' => 'chinacgcgcg@163.com' }
  s.source       = { :git => "https://github.com/charlesYun/YXNetworkManager", :tag => "0.0.2" }
  s.ios.deployment_target = '9.0'
  s.source_files = "YXNetworkManager/*.{h,m}"
  s.requires_arc = true
  s.dependency 'AFNetworking', "~> 3.1.0"
  s.dependency 'YYCache'
  s.dependency 'YYModel'

end