require 'rubygems' 
require 'sinatra'
require 'koala'
require 'json'
require 'face'
require 'debugger'
require 'uri'

enable :sessions
set :raise_errors, false
set :show_exceptions, false

enable :sessions
# Scope defines what permissions that we are asking the user to grant.
# In this example, we are asking for the ability to publish stories
# about using the app, access to what the user likes, and to be able
# to use their pictures.  You should rewrite this scope with whatever
# permissions your app needs.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions
FACEBOOK_SCOPE = 'user_likes,user_photos'

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
end

helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))

  end

  # allow for javascript authentication
  def access_token_from_cookie
    authenticator.get_user_info_from_cookies(request.cookies)['access_token']
  rescue => err
    warn err.message
  end

  def access_token
    session[:access_token] || access_token_from_cookie
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  session[:access_token] = nil
  redirect "/auth/facebook"
end





#############
get "/" do
  # Get base API Connection
 
  @graph  = Koala::Facebook::API.new(access_token)
  @client = Face.get_client(:api_key => 'ad8d512de5354372ba24ea2c328a58c1', :api_secret => '83b9c2f388614e03b2ba72d42fac0e7c')

#debugger

  # Get public details of current application
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])
  if access_token
  authenticator.get_user_info_from_cookies(session[:access_token])

    @user    = @graph.get_object("me")
    @friends = @graph.get_connections('me', 'friends')
    @photos  = @graph.get_connections('me', 'photos')
    @likes   = @graph.get_connections('me', 'likes').first(4)
    @user_id = @user['id']

    # for other data you can always run fql
    @friends_using_app = @graph.fql_query("SELECT uid, name, is_app_user, pic_square FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1")
  end
  erb :index
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

# used to close the browser window opened to post to wall/send to friends
get "/close" do
  "<body onload='window.close();'/>"
end

# Doesn't actually sign out permanently, but good for testing
get "/preview/logged_out" do
  session[:access_token] = nil
  request.cookies.keys.each { |key, value| response.set_cookie(key, '') }
  redirect '/'
end


# Allows for direct oauth authentication
get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  session[:access_token] = authenticator.get_access_token(params[:code])
  redirect '/'
end

get '/logout' do
  session[:authenticated] = false
  redirect '/'
end
  
def face_check
  #debugger
   #h  = @client.faces_detect(:urls => ['http://skybiometry.com/Content/Samples/two.jpg'], :attributes => 'all')
   #k  = @client.faces_detect(:urls => ['http://skybiometry.com/Content/Samples/one_i.jpg'], :attributes => 'all')

# #of ppl = h['photos'][0]['tags'].length

   #h  = @client.faces_detect(:file => File.new('me.jpg', 'rb'), :attributes => 'all')
   #@user_id = 'acarrington3'
 h  = @client.faces_detect(:urls => ['https://graph.facebook.com/'+@user_id+'/picture?type=large'], :attributes => 'all')
  @features =  h['photos'][0]['tags'][0]['attributes']

end

def number

  
   h  = @client.faces_detect(:urls => ['http://skybiometry.com/Content/Samples/two.jpg'], :attributes => 'all')
   result = h['photos'][0]['tags'].length
   return result
end

