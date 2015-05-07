module Helpers
  def application_config
    @application_config ||= begin
      application_config_path = File.join(File.expand_path(File.dirname(__FILE__)), 's3_config.yml')
      puts application_config_path

      if File.exists?(application_config_path)
        YAML.load(File.read(application_config_path))
      else
        puts "cannot run tests without application config"
        exit 1
      end
    end
  end

  def connect_bucket
    s3 = AWS::S3.new(
      access_key_id: application_config['aws_asset_access_key'],
      secret_access_key: application_config['aws_asset_secret_access_key']
    )

    bucket = s3.buckets[application_config['aws_asset_bucket']]

    if !bucket.exists?
      puts "failed to find bucket on S3!".red
      return
    end

    bucket
  end
end
