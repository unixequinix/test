class EventSeriePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def new?
    user.admin?
  end

  def create?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def add_event?
    user.admin?
  end

  def remove_event?
    user.admin?
  end

  def copy_data?
    user.admin?
  end

  def copy_serie?
    user.admin?
  end
end
