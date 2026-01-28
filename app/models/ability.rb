# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      # Admin can manage everything
      can :manage, :all
    elsif user.sales_executive?
      # Sales executive can read all users and update their own profile
      can :read, User
      can :update, User, id: user.id
      # Sales executive can manage customers
      can :manage, Customer
      # Sales executive can manage packages and addons
      can :manage, Package
      can :manage, Addon
      # Sales executive can manage all orders and add feedback
      can :manage, Order
      can :add_feedback, Order
    elsif user.agent?
      # Agent can read their own profile and update it
      can :read, User, id: user.id
      can :update, User, id: user.id
      # Agent can manage customers
      can :manage, Customer
      # Agent can read packages and addons
      can :read, Package
      can :read, Addon
      # Agent can read assigned orders and update status/actual times/notes
      can :read, Order, assigned_to_id: user.id
      can [:update_status, :update], Order, assigned_to_id: user.id
    elsif user.accountant?
      # Accountant can read all users and update their own profile
      can :read, User
      can :update, User, id: user.id
      # Accountant can read customers
      can :read, Customer
      # Accountant can read packages and addons
      can :read, Package
      can :read, Addon
      # Accountant can read all orders (read-only)
      can :read, Order
    end

    # Define abilities for the user here. For example:
    #
    #   return unless user.present?
    #   can :read, :all
    #   return unless user.admin?
    #   can :manage, :all
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, published: true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md
  end
end
