require 'right_aws'
require 'encryptor'

class S3Helper
  CONFIG_PATH = File.expand_path("../../../config/s3.yml",__FILE__)
  
  def self.s3_enabled?
    return @s3_enabled if @s3_enabled
    @s3_enabled ||= !config.empty? &&
      !config["creds"].empty?    &&
      !config["creds"]["aws_access_key_id"].nil? &&
      config["creds"]["aws_access_key_id"] != "@@AWS_ACCESS_KEY_ID@@"
  end

  def self.config
    @config ||=  YAML.load_file(CONFIG_PATH)[ENV['RACK_ENV']]
  end

  def self.s3
    @s3 ||= Rightscale::S3.new config["creds"]["aws_access_key_id"], @config["creds"]["aws_secret_access_key"]
  end

  def self.bucket
    #TO DISCUSS: second param 'true' means 'create new bucket'
    #@bucket ||= s3.bucket(config["bucket_name"], true)
    @bucket ||= s3.bucket(config["bucket_name"])
  end

  def self.aeds_master_secret
    config["aeds_master_secret"]
  end
    
  def self.get(key)
    return nil unless s3_enabled?
    
    object = bucket.key(key, true)
    return nil if object.nil?
    
    # don't decrypt/verify unencrypted values
    return object.data if object.meta_headers["digest"].nil?
    
    ciphertext = object.data
    passphrase = "#{key}:#{aeds_master_secret}"
    plaintext = Encryptor.decrypt(:key=>passphrase, :value=>ciphertext)
    digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, passphrase, plaintext)
    
    if digest == object.meta_headers["digest"]
      return plaintext
    else
      raise "digest for key:#{key} in s3 does not match calculated digest."
    end
  end

  def self.post(key, plaintext)
    passphrase = "#{key}:#{aeds_master_secret}"
    ciphertext = Encryptor.encrypt(:key=>passphrase, :value=>plaintext)
    digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, passphrase, plaintext)
    bucket.put(key, ciphertext, "digest" => digest)
  end

end
