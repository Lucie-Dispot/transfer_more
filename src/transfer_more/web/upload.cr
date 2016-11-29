require "secure_random"

put "/:file_name" do |env|
  file_name = env.params.url["file_name"].downcase
  dir = Time.now.to_s(TransferMore::TIME_FORMAT) + "/" + SecureRandom.hex(4)

  Dir.mkdir_p(TransferMore.storage "files/#{dir}")

  visible_path = "#{dir}/#{file_name}"
  file_path = TransferMore.storage "files/#{visible_path}"

  # TODO: when kemal will, use env.files["upload"]
  begin
    parse_multipart(env) do |f|
      while read = f.data.gets(65536)
        File.write(file_path, read)
      end
      break # only one file upload
    end
  rescue err
    File.write(file_path, env.request.body.as(IO).gets_to_end)
  end

  TransferMore::BASE_URL + "/" + visible_path + "\n"
end

get "/:part1/:part2/:file_name" do |env|
  file_name = env.params.url["file_name"].downcase
  path = TransferMore.storage("files") + "/" + env.params.url["part1"] + "/" + env.params.url["part2"] + "/" + file_name
  begin
    content_type = TransferMore::MimeSearch.new(path).get_content_type
    env.response.content_type = content_type
    File.read(path)
  rescue
    env.response.status_code = 404
  end
end

get "/" do |env|
  render "src/views/index.ecr"
end
