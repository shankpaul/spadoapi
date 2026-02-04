# Subscription State Machines

The Subscription model uses AASM gem with two separate state machines to manage subscription lifecycle and payment status.

## Status State Machine (`:status` column)

Manages the subscription lifecycle.

### States
- `scheduled` (initial) - Subscription created but not yet started
- `active` - Subscription is currently active
- `paused` - Subscription temporarily paused by user
- `completed` - Subscription finished successfully
- `cancelled` - Subscription cancelled by user
- `expired` - Subscription expired without completion

### Events & Transitions
```ruby
activate!    # scheduled -> active
pause!       # active -> paused
resume!      # paused -> active
complete!    # active/paused -> completed (requires all_orders_completed?)
cancel!      # scheduled/active/paused -> cancelled (cancels pending orders)
expire!      # scheduled/active/paused -> expired
```

### Predicate Methods
```ruby
subscription.scheduled?   # true if status == 'scheduled'
subscription.active?      # true if status == 'active'
subscription.paused?      # true if status == 'paused'
subscription.completed?   # true if status == 'completed'
subscription.cancelled?   # true if status == 'cancelled'
subscription.expired?     # true if status == 'expired'
```

### Guard Methods
```ruby
subscription.may_activate?   # can transition to active?
subscription.may_pause?      # can transition to paused?
subscription.may_resume?     # can transition to active from paused?
subscription.may_complete?   # can transition to completed?
subscription.may_cancel?     # can transition to cancelled?
subscription.may_expire?     # can transition to expired?
```

## Payment State Machine (`:payment_status` column)

Manages payment status separately from subscription status.

### States
- `pending` (initial) - Payment not yet received
- `paid` - Payment received in full
- `payment_cancelled` - Payment cancelled/refunded
- `failed` - Payment attempt failed

### Events & Transitions
```ruby
mark_paid!       # pending/failed -> paid
mark_cancelled!  # pending/paid/failed -> payment_cancelled
mark_failed!     # pending -> failed
```

### Predicate Methods
```ruby
subscription.pending?             # true if payment_status == 'pending'
subscription.paid?                # true if payment_status == 'paid'
subscription.payment_cancelled?   # true if payment_status == 'payment_cancelled'
subscription.failed?              # true if payment_status == 'failed'
```

### Guard Methods
```ruby
subscription.may_mark_paid?       # can transition to paid?
subscription.may_mark_cancelled?  # can transition to payment_cancelled?
subscription.may_mark_failed?     # can transition to failed?
```

## Usage Examples

### Creating a Subscription
```ruby
# Subscription starts in 'scheduled' status and 'pending' payment_status
subscription = Subscription.create(...)
subscription.scheduled?  # => true
subscription.pending?    # => true
```

### Activating on First Order
```ruby
if subscription.may_activate?
  subscription.activate!  # scheduled -> active
end
```

### Managing Payments
```ruby
# Mark payment as received
if subscription.may_mark_paid?
  subscription.mark_paid!  # pending -> paid
end

# Handle payment failure
if subscription.may_mark_failed?
  subscription.mark_failed!  # pending -> failed
end
```

### Pausing and Resuming
```ruby
# User pauses subscription
if subscription.may_pause?
  subscription.pause!  # active -> paused
end

# User resumes subscription
if subscription.may_resume?
  subscription.resume!  # paused -> active
end
```

### Completing Subscription
```ruby
# Auto-complete when all orders are done
if subscription.all_orders_completed? && subscription.may_complete?
  subscription.complete!  # active/paused -> completed
end
```

### Cancelling Subscription
```ruby
# User cancels subscription
if subscription.may_cancel?
  subscription.cancel!  # scheduled/active/paused -> cancelled
  # Also cancels all pending orders via callback
end
```

### Expiring Subscriptions
```ruby
# Rake task expires old subscriptions
Subscription.where('end_date < ?', Date.current)
            .where(status: [:scheduled, :active, :paused])
            .find_each do |subscription|
  if subscription.may_expire?
    subscription.expire!  # scheduled/active/paused -> expired
  end
end
```

## Important Notes

1. **No Parameters**: Predicate and event methods don't take parameters. The first state machine (`:status`) gets default method names, while the second (`:payment`) has some methods prefixed with the state name.

2. **State Name Conflicts**: The payment state machine originally had `cancelled` state but it was renamed to `payment_cancelled` to avoid conflicts with the status state machine's `cancelled` state.

3. **String Storage**: Both state machines store states as strings in the database (not integers/enums).

4. **Guards**: Always use `may_*?` methods to check if a transition is valid before calling the event method.

5. **Callbacks**: Some events trigger callbacks:
   - `cancel!` calls `cancel_pending_orders` after transition
   - `complete!` requires `all_orders_completed?` guard to be true

6. **Independent States**: Status and payment states are completely independent. A subscription can be `active` with `pending` payment, or `scheduled` with `paid` payment, etc.
