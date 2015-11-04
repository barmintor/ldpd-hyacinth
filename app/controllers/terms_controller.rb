class TermsController < ApplicationController
  before_action :set_term, only: [:show, :edit, :update, :destroy]
  before_action :set_controlled_vocabulary, only: [:new, :create, :show, :edit, :update, :destroy]
  before_action :require_appropriate_permissions!
  before_action :set_contextual_nav_options

  # GET /terms/1
  # GET /terms/1.json
  def show
  end

  # GET /terms/new
  def new
    #@term = AuthorizedTerm.new
    #@term.controlled_vocabulary = ControlledVocabulary.find(params[:controlled_vocabulary_id])
  end

  # GET /terms/1/edit
  def edit
  end

  # POST /terms
  # POST /terms.json
  def create
    
    @errors = []
    term_prms = term_params
    
    @errors << 'A type is required for a new Term.' if term_prms['type'].blank?
    @errors << 'A Controlled Vocabulary must be set for a new Term.' if term_prms['controlled_vocabulary_string_key'].blank?
    @errors << 'A value is required for a new Term.' if term_prms['value'].blank?
    
    unless @errors.present?
      
      type = term_prms.delete('type')
      
      new_term_opts = {}
      new_term_opts[:vocabulary_string_key] = term_prms.delete('controlled_vocabulary_string_key')
      new_term_opts[:value] = term_prms.delete('value')
      
      # Delete fields that are blank. This is okay because we're in the create method and aren't using blank fields to clear out existing fields.
      term_prms.delete_if{|key, value| value.blank?}
      
      new_term_opts[:uri] = term_prms.delete('uri') if term_prms.has_key?('uri')
      
      unless type == UriService::TermType::TEMPORARY
        # Do not set additional_fields for TEMPORARY terms.
        # For non-TEMPORARY terms, assume treat all remaining (non-deleted) parameters as additional_fields.
        new_term_opts[:additional_fields] = term_prms if term_prms.present?
      end
      
      begin
        @term = UriService.client.create_term(
          type,
          new_term_opts
        )
      rescue UriService::NonExistentVocabularyError, UriService::InvalidUriError, UriService::ExistingUriError, UriService::InvalidAdditionalFieldKeyError, UriService::InvalidOptsError => e
        @errors << e.message
      end
    end

    respond_to do |format|
      if @errors.blank?
        format.html { redirect_to term_path(@term['uri']), notice: 'Term was successfully created.' }
        format.json {
          render json: @term
        }
      else
        format.html { render action: 'new' }
        format.json { render json: {
            errors: @errors
          }
        }
      end
    end
  end

  # PATCH/PUT /terms/1
  # PATCH/PUT /terms/1.json
  def update
    @errors = []
    term_prms = term_params
    
    begin
      @term = UriService.client.update_term(term_prms['uri'],
        { value: term_prms['value'], additional_fields: term_prms['additional_fields']}
      )
    rescue UriService::NonExistentUriError, UriService::InvalidAdditionalFieldKeyError => e
      @errors << e.message
    end

    respond_to do |format|
      if @errors.blank?
        format.html { redirect_to term_path(@term['uri']), notice: 'Term was successfully updated.' }
        format.json {
          render json: @term
        }
      else
        format.html { render action: 'new' }
        format.json { render json: {
            errors: @errors
          }
        }
      end
    end
    
  end

  # DELETE /terms/1
  # DELETE /terms/1.json
  def destroy
    UriService.client.delete_term(@term['uri'])
    respond_to do |format|
      format.html { redirect_to terms_controlled_vocabulary_path(@controlled_vocabulary), notice: 'Term has been deleted.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_term
    @term = UriService.client.find_term_by_uri(params[:id])
    raise ActionController::RoutingError.new('Could not find Term with URI: ' + params[:id]) if @term.nil?
  end
  
  def set_controlled_vocabulary
    if params[:action] == 'new'
      @controlled_vocabulary = ControlledVocabulary.find_by!(string_key: params[:controlled_vocabulary_string_key])
    elsif params[:action] == 'create'
      @controlled_vocabulary = ControlledVocabulary.find_by!(string_key: params[:term]['controlled_vocabulary_string_key'])
    else
      @controlled_vocabulary = ControlledVocabulary.find_by!(string_key: @term['vocabulary_string_key'])
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def term_params
    params.require(:term).permit([
      :controlled_vocabulary_string_key, :value, :uri, :type,
    ] + (TERM_ADDITIONAL_FIELDS[params[:term]['controlled_vocabulary_string_key']].map{|key, value| key.to_sym}))
  end

  def adjust_params_if_controlled_vocabulary_string_key_is_present
    # Also handle creation via controlled_vocabulary string_key
    if params[:term] && params[:term]['controlled_vocabulary_string_key'].present?
      controlled_vocabulary = ControlledVocabulary.find_by(string_key: params[:term]['controlled_vocabulary_string_key'])
      params[:term].delete('controlled_vocabulary_string_key')
      params[:term][:controlled_vocabulary_id] = controlled_vocabulary.id
    end
  end

  def require_appropriate_permissions!
    case params[:action]
    when 'new', 'create', 'edit', 'update', 'delete'
      require_controlled_vocabulary_permission!(@controlled_vocabulary)
    end
  end

  def set_contextual_nav_options
    @contextual_nav_options['nav_title']['label'] =  ('&laquo; Back to Controlled Vocabulary: ' + @controlled_vocabulary.display_label).html_safe
    @contextual_nav_options['nav_title']['url'] = terms_controlled_vocabulary_path(@controlled_vocabulary)

    case params[:action]
    when 'show'
      @contextual_nav_options['nav_items'].push(label: 'Edit', url: edit_term_path(@term['uri'])) if current_user.can_manage_controlled_vocabulary_terms?(@controlled_vocabulary)
    when 'edit', 'update'
      @contextual_nav_options['nav_title']['label'] =  ('&laquo; Cancel Edit').html_safe
      @contextual_nav_options['nav_title']['url'] = term_path(@term['uri'])

      @contextual_nav_options['nav_items'].push(label: 'Delete This Term', url: term_path(@term['uri']), options: {method: :delete, data: { confirm: 'Are you sure you want to delete this Term?' } }) if current_user.can_manage_controlled_vocabulary_terms?(@controlled_vocabulary)
    end

  end
end