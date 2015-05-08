require 'pathname'
require 'thread'
require 'mimemagic'

module S3AssetSync
  class Uploader
    attr_reader :bucket

    def initialize(bucket, origin, relative_root, upload_client_count=1)
      @bucket = bucket
      @origin = origin
      @root = relative_root

      @upload_queue = Queue.new
      @upload_client_count = upload_client_count
      @upload_clients = []
    end

    def upload!
      add_upload_files_from(@origin)

      puts "[S3 Asset Sync] queued #{ @upload_queue.size } files for upload"

      @upload_client_count.times do
        client = UploadClient.new(bucket, @root, @upload_queue)
        client.run
        @upload_clients << client
      end

      @upload_clients.map(&:join)
    end

    def add_upload_files_from(directory)
      Dir.foreach(directory) do |file|
        next if file == '.' || file == '..'

        # always deal in absolute filepaths at this level
        file = File.join(directory, file)

        if File.directory?(file)
          add_upload_files_from(file)
        else
          @upload_queue << file
        end
      end
    end
  end

  class UploadClient
    def initialize(bucket, root, queue)
      @bucket = bucket
      @file_root = Pathname.new(root)
      @queue = queue
    end

    def join
      @thread.join
    end

    def run
      @thread = Thread.new do
        begin
          while key = @queue.pop(true)
            if !s3_object_exists?(key)
              s3_upload_object(key)
            end
          end
        rescue ThreadError
          # queue is empty
        end
      end
    end

    def get_key(file)
      filepath = Pathname.new(file)
      filepath.relative_path_from(@file_root)
    end

    ##
    # Check if a key exists in the specified S3 Bucket.
    #
    def s3_object_exists?(file)
      key = get_key(file)
      obj = @bucket.objects[key]
      obj.exists?
    end

    ##
    # Uploads an object to the specified S3 Bucket.
    #
    def s3_upload_object(file)
      key = get_key(file)
      puts "#{file} -> #{key}"

      obj = @bucket.objects[key]

      metadata = {}

      # metadata
      if /\.gz$/ =~ key.to_s
        metadata[:content_encoding] = 'gzip'
      end

      # attempt to access mimetype
      begin
        mime_type = ::MimeMagic.by_path(key.to_s)
        metadata[:content_type] = mime_type
      rescue => ex
        # it's okay to lose this information
        puts "unable to determine mime type for #{ key }: #{ ex.message }"
      end

      obj.write(File.read(File.join(@file_root, key)), metadata)
      obj
    end
  end
end
