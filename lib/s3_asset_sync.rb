require 'colorize'
require 'aws-sdk'
require 's3_asset_sync/railtie' if defined?(Rails)
require 'pathname'

module S3AssetSync

  ##
  # Loops through /public/assets directory and sync's each
  # file with the specified S3 Bucket.
  #
  def self.sync
    puts "Syncing assets to S3...".yellow

    s3 = AWS::S3.new(
      access_key_id: Rails.application.config.s3_asset_sync.s3_access_key,
      secret_access_key: Rails.application.config.s3_asset_sync.s3_secret_access_key
    )

    bucket = s3.buckets[Rails.application.config.s3_asset_sync.s3_bucket]

    if !bucket.exists?
      puts "Failed to find bucket on S3!".red
      return
    end

    self.upload_directory(bucket, Rails.root.join('public','assets'))

    puts "Asset sync successfully completed...".green
  end

  def self.upload_directory(bucket, directory)
    Dir.foreach(directory) do |file|
      next if file == '.' || file == '..'

      # always deal in absolute filepaths at this level
      file = File.join(directory, file)

      if File.directory?(file)
        self.upload_directory(bucket, file)
      else
        self.s3_upload_object(bucket, file) unless self.s3_object_exists?(bucket, file)
      end
    end
  end

  ##
  # Loops through specified S3 Bucket and checks to see if the object
  # exists in our /public/assets folder. Deletes it from the
  # bucket if it doesn't exist.
  #
  def self.purge
    puts "Cleaning assets in S3...".yellow

    # FIXME: use aws-sdk-v1 for this
    # s3 = AWS::S3.new(
    #   access_key_id: Rails.application.config.s3_asset_sync.s3_access_key,
    #   secret_access_key: Rails.application.config.s3_asset_sync.s3_secret_access_key
    # )

    # keys = []

    # s3.list_objects(bucket:Rails.application.config.s3_asset_sync.s3_bucket).each do |response|
    #   keys += response.contents.map(&:key)
    # end

    # keys.each do |key|
    #   if !File.exists?(Rails.root.join('public', 'assets', key))
    #     self.s3_delete_object(s3, key)
    #     puts "DELETED: #{key}"
    #   end
    # end

    puts "Asset clean successfully completed...".green
  end

  def self.get_key(file)
    filepath = Pathname.new(file)
    # everything should go in /assets on S3 since Rails generates URLs in the form of /assets/$OBJECT
    filepath.relative_path_from(Rails.root.join('public'))
  end

  ##
  # Check if a key exists in the specified S3 Bucket.
  #
  def self.s3_object_exists?(bucket, file)
    key = self.get_key(file)
    obj = bucket.objects[key]
    obj.exists?
  end

  ##
  # Uploads an object to the specified S3 Bucket.
  #
  def self.s3_upload_object(bucket, file)
    key = self.get_key(file)
    puts "#{file} -> #{key}"

    obj = bucket.objects[key]
    obj.write(Rails.root.join('public', key))
    obj
  end

  ##
  # Deletes an object from the specified S3 Bucket.
  #
  def self.s3_delete_object(bucket, key)
    obj = bucket.objects[key]
    if obj.exists?
      obj.delete
    end
  end

end

