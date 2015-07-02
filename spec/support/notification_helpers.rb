module NotificationHelpers
  def with_subscription_to(matcher, notification_callable)
    subscription = ActiveSupport::Notifications.subscribe(matcher, notification_callable)
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end
end
