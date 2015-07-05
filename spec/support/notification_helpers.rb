module NotificationHelpers
  def with_subscription_to(matcher, notification_callable)
    subscription = ActiveSupport::Notifications.subscribe(matcher, notification_callable)
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  def listeners_for(event_name)
    ActiveSupport::Notifications.notifier.listeners_for(event_name)
  end

  def subscribers_for(event_name)
    listeners_for(event_name).map{ |listener|
      listener.instance_variable_get('@delegate')
    }
  end

  def subscriber_classes_for(event_name)
    subscribers_for(event_name).map(&:class)
  end
end
