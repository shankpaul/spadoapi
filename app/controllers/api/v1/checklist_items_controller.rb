class Api::V1::ChecklistItemsController < ApplicationController
  before_action :authenticate_request!
  before_action :set_checklist_item, only: [:show, :update, :destroy]
  
  # GET /api/v1/checklist_items
  def index
    @checklist_items = ChecklistItem.active.order(:when, :position)
    
    # Filter by package if provided
    if params[:package_id].present?
      @checklist_items = @checklist_items.joins(:packages).where(packages: { id: params[:package_id] })
    end
    
    render json: {
      checklist_items: @checklist_items.as_json(only: [:id, :name, :when, :active, :position])
    }
  end
  
  # GET /api/v1/checklist_items/:id
  def show
    render json: {
      checklist_item: @checklist_item.as_json(
        only: [:id, :name, :when, :active, :position],
        include: {
          packages: { only: [:id, :name] }
        }
      )
    }
  end
  
  # POST /api/v1/checklist_items
  def create
    authorize! :manage, ChecklistItem
    
    @checklist_item = ChecklistItem.new(checklist_item_params)
    
    if @checklist_item.save
      # Associate with packages if provided
      if params[:package_ids].present?
        @checklist_item.package_ids = params[:package_ids]
      end
      
      render json: {
        message: 'Checklist item created successfully',
        checklist_item: @checklist_item.as_json(
          only: [:id, :name, :when, :active, :position],
          include: {
            packages: { only: [:id, :name] }
          }
        )
      }, status: :created
    else
      render json: { errors: @checklist_item.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/checklist_items/:id
  def update
    authorize! :manage, ChecklistItem
    
    if @checklist_item.update(checklist_item_params)
      # Update package associations if provided
      if params[:package_ids].present?
        @checklist_item.package_ids = params[:package_ids]
      end
      
      render json: {
        message: 'Checklist item updated successfully',
        checklist_item: @checklist_item.as_json(
          only: [:id, :name, :when, :active, :position],
          include: {
            packages: { only: [:id, :name] }
          }
        )
      }
    else
      render json: { errors: @checklist_item.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/checklist_items/:id
  def destroy
    authorize! :manage, ChecklistItem
    
    @checklist_item.destroy
    render json: { message: 'Checklist item deleted successfully' }
  end
  
  private
  
  def set_checklist_item
    @checklist_item = ChecklistItem.find(params[:id])
  end
  
  def checklist_item_params
    params.require(:checklist_item).permit(:name, :when, :active, :position)
  end
end
