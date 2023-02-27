class ApplicationController < ActionController::Base

    rescue_from StandardError, with: :unhandled_error
    rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token

    rescue_from BrewException, with: :handle_brew_exception
    
    include ActionController::RequestForgeryProtection
    protect_from_forgery with: :exception

    # update this line:
    # before_action :snake_case_params, :attach_authenticity_token
    before_action :snake_case_params, :attach_authenticity_token, :require_logged_in

    def handle_brew_exception
        render json: ["I can't brew; I'm a teapot!"], status: 418
    end

    def current_user
        # user whose `session_token` == token in `session` cookie
        @current_user ||= User.find_by(session_token: session[:session_token])
    end
    
    def login!(user)
        # reset `user`'s `session_token` and store in `session` cookie
        session[:session_token] = user.reset_session_token!
    end
    
    def logout!
        # reset the `current_user`'s session cookie, if one exists
        # clear out token from `session` cookie
        @current_user = nil # so that subsequent calls to `current_user` return nil
        session[:session_token] = nil
    end
    
    def require_logged_in
        unless current_user
            render json: { message: 'Unauthorized' }, status: :unauthorized
        end
    end

    def test
        if params.has_key?(:login)
            login!(User.first)
        elsif params.has_key?(:logout)
            logout!
        end

        if current_user
            render json: { user: current_user.slice('id', 'username', 'session_token') }
        else
            render json: ['No current user']
        end
    end

    private

    def invalid_authenticity_token
        render json: { message: 'Invalid authenticity token' }, 
            status: :unprocessable_entity
    end
    
    def unhandled_error(error)
        if request.accepts.first.html?
            raise error
        else
            @message = "#{error.class} - #{error.message}"
            @stack = Rails::BacktraceCleaner.new.clean(error.backtrace)
            render 'api/errors/internal_server_error', status: :internal_server_error
        
            logger.error "\n#{@message}:\n\t#{@stack.join("\n\t")}\n"
        end
    end

    # add this method to the `private` section of your controller:
    def attach_authenticity_token
        headers['X-CSRF-Token'] = masked_authenticity_token(session)
    end

    def snake_case_params
        params.deep_transform_keys!(&:underscore)
    end
end