# azure-event-grid-duplicate-protection

<i>
When Event Grid encounters an error during event delivery, it evaluates whether to retry the delivery, dead-letter the event, or discard it based on the nature of the error.

If the error occured due to a configuration issue at the subscribed endpoint, such as the endpoint being deleted, Event Grid will either dead-letter the event or discard it if dead-lettering isn't configured, as retries won't resolve the issue.

Event Grid attempts to remove events from the retry queue within 3 minutes if the endpoint responds promptly, but duplicate events may still occur.

To mitigate this, it's essential to implement safeguards in the event handler to prevent processing duplicate events. For instance, when utilizing the service bus queue event handler:

- This can be accomplished by configuring Custom delivery properties in the event subscription to map the event's ID to the MessageId header property of the service bus queue message.
- When multiple events with the same `MessageId` are received, the Service Bus Queue will automatically discard the duplicate messages.

Since Event Grid doesn't ensure event delivery order, subscribers should be prepared to receive events out of sequence.

</i>

## To test:
- Provision resources in Azure:

### run:
- From `tf` folder:

- terraform init
- terraform plan -out main.tfplan
- terraform apply main.tfplan

### Send duplicate messages and confirm the receipt of only one message:

#### From `send-event` folder:
    - pip install -r requiremets.txt
    - az login --use-device-code
    - python send_and_receive_events.py

#### Note: change to `requires_duplicate_detection = false` in the resource `azurerm_servicebus_queue` in `main.tf` and re-run 
    - terraform plan -out main.tfplan
    - terraform apply main.tfplan

- repeat the test to see `assertion` fails when two messages are received.

## Cleanup steps

- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan



## Ref: 

- https://learn.microsoft.com/en-us/azure/event-grid/delivery-properties 

- https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection

- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-python-how-to-use-queues?tabs=passwordless 