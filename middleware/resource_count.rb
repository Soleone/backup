# Rack::Middleware that returns the number of models in the database for any call to a URL like modelname/count.
#
# Examples:
#   /users/count
#     => returns User.count in plain text
#
#  /articles/1/comments/count.xml
#    => returns Comment.count as XML, e.g.
#       <comments type="integer">5</comments>
#       Note: this does not return Articles.find(1).comments.count like it maybe should!
#
# Usage:
#   Simply require in environment.rb with config.middleware.use "ResourceCount"
#
# Requirements:
#   1.) Use Rails conventions (controller name is pluralized name of model)
#   2.) Model.count should be available, but size or length also works
#   3.) These String methods from Rails need to be available: singularize, classify and constantize
class ResourceCount

  def initialize(app)
    @app = app
  end

  def call(env)
    dup.count(env)
  end

  def count(env)
    if env['PATH_INFO'] =~ %r{/(.+)/count(\.xml)?$}
      model_name = $1.singularize.classify.constantize
      count = model_name.count rescue model_name.size rescue model_name.length
    
      if $2 == '.xml'
        @body = "<#{$1} type=\"integer\">#{count}</#{$1}>"
        @content_type = 'text/xml'
      else
        @body = count.to_s
        @content_type = 'text/plain'
      end
      [200, {'Content-Type' => @content_type, 'Content-Length' => @body.length.to_s}, @body]
    
    else
      @app.call(env)
    end
  end
end