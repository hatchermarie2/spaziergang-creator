class PagesController < ApplicationController
  include PagesHelper
  before_action :authenticate_user!
  before_action :is_user_blocked, only: [:create,
                                         :update,
                                         :delete,
                                         :sort,
                                         :update_after_sort]
  before_action :set_page, only: [:show, :edit, :update, :destroy]
  before_action :set_subject, only: [:new, :create, :sort]
  before_action :ensure_user_rights, only: [:show, :edit, :update, :destroy]
  before_action :has_enough_pages_to_sort, only: [:sort]

  include BreadcrumbsHelper

  def show
    @challenges = pages_parse_list @page.challenges if @page.challenges.present?
    @answers = pages_parse_list(@page.answers) if @page.answers.present?
    @correct_answer = pages_correct_answer_index(@answers) if @answers

    breadcrumb_walk_helper(@page.subject.station.walk)
    breadcrumb_station_helper(@page.subject.station)
    breadcrumb_subject_helper(@page.subject)
    breadcrumb_page_helper(@page)
  end

  def new
    @page = Page.new

    breadcrumb_walk_helper(@subject.station.walk)
    breadcrumb_station_helper(@subject.station)
    breadcrumb_subject_helper(@subject)
    add_breadcrumb t('page.new'), new_subject_page_path(@subject)
  end

  def create
    @page = Page.new(page_params)
    @page.user_id = current_user.id
    @page.subject_id = @subject.id
    @page.priority = @subject.next_page_priority
    if @page.save!
      @subject.set_next_on_collection!(@subject.pages) if @page.priority > 0
      @subject.set_prev_on_collection!(@subject.pages) if @page.priority != 0
      redirect_to page_path(@page), notice: t('page.saved')
    else
      render action: :new
    end
  end

  def edit
    breadcrumb_walk_helper(@page.subject.station.walk)
    breadcrumb_station_helper(@page.subject.station)
    breadcrumb_subject_helper(@page.subject)
    breadcrumb_page_helper(@page)
    add_breadcrumb t('page.edit'), edit_page_path(@page)
  end

  def update
    if @page.update(page_params)
      redirect_to page_path(@page), notice: t('page.edited')
    else
      render action: :edit
    end
  end

  def sort
    breadcrumb_walk_helper(@subject.station.walk)
    breadcrumb_station_helper(@subject.station)
    breadcrumb_subject_helper(@subject)
    add_breadcrumb t('page.change_order'), sort_subject_pages_path(@subject)
  end


  def update_after_sort
    @updates = params[:data]

    @updates.each_with_index do |v, i|
      page = Page.find(v['id'])
      page.priority = v['pos'].to_i

      if v['pos'].to_i == 0
        page.prev = nil
      else
        page.prev = @updates[i - 1]['pos'].to_i
      end

      if @updates[i + 1].present?
        page.next = @updates[i + 1]['pos'].to_i
      else
        page.next = nil
      end

      if page.save!
        head :ok
      else
        head :forbidden
      end
    end
  end

  def destroy
    @subject = @page.subject
    @page.destroy
    if @subject.pages
      @subject.set_next_on_collection!(@subject.pages)
      @subject.set_prev_on_collection!(@subject.pages)
    end
    redirect_to subject_path(@subject), notice: t('page.deleted')
  end

  private

  def ensure_user_rights
    render_403 unless current_user == @page.user || current_user.admin?
  end

  def has_enough_pages_to_sort
    redirect_to subject_path(@subject), notice: t("pages.cannot_sort") if @subject.pages.count < 2
  end

  def set_page
    @page = Page.find(params[:id])
  end

  def set_subject
    @subject = Subject.find(params[:subject_id])
  end

  def page_params
    params.require(:page).permit(:name,
                                 :variant,
                                 :subject_id,
                                 :user_id,
                                 :content,
                                 :challenges,
                                 :link,
                                 :question,
                                 :answers)
  end
end
