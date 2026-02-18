class Api::V1::PackageChecklistItemsController < ApplicationController
  before_action :authenticate_request!
  before_action :set_package
  
  # GET /api/v1/packages/:package_id/checklist_items
  def index
    @checklist_items = @package.checklist_items.active
    
    render json: {
      package_id: @package.id,
      package_name: @package.name,
      checklist_items: @checklist_items.as_json(only: [:id, :name, :when, :active, :position])
    }
  end
  
  # POST /api/v1/packages/:package_id/checklist_items/:checklist_item_id
  def create
    authorize! :manage, Package
    
    checklist_item = ChecklistItem.find(params[:checklist_item_id])
    
    unless @package.checklist_items.include?(checklist_item)
      @package.checklist_items << checklist_item
      render json: { message: 'Checklist item added to package successfully' }, status: :created
    else
      render json: { message: 'Checklist item already associated with this package' }
    end
  end
  
  # DELETE /api/v1/packages/:package_id/checklist_items/:checklist_item_id
  def destroy
    authorize! :manage, Package
    
    checklist_item = ChecklistItem.find(params[:checklist_item_id])
    
    if @package.checklist_items.delete(checklist_item)
      render json: { message: 'Checklist item removed from package successfully' }
    else
      render json: { message: 'Checklist item not found in this package' }, status: :not_found
    end
  end
  
  private
  
  def set_package
    @package = Package.find(params[:package_id])
  end
end
