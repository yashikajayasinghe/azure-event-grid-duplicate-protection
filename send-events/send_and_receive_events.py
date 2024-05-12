from azure.identity import DefaultAzureCredential
from azure.eventgrid import EventGridPublisherClient, EventGridEvent
from azure.servicebus import ServiceBusClient

from datetime import datetime

import uuid
import json

eventgrid_endpoint = "https://eg-topic-yazure-onnline.australiaeast-1.eventgrid.azure.net/api/events"
FULLY_QUALIFIED_NAMESPACE = "sb-yazure-online.servicebus.windows.net"
QUEUE_NAME = "eg-subscription-queue"
random_uuid = uuid.uuid4()
now = datetime.now().strftime('%a %d %b %Y, %I:%M%p')
credential = DefaultAzureCredential()

# Send event
client = EventGridPublisherClient(eventgrid_endpoint, credential)

# Sending two duplicate events with the same `id`
client.send([
	EventGridEvent(
		event_type="Yazure.Online.Event",
		data={
			"id":random_uuid,
            "name": f"user_{random_uuid}"
		},
		subject="Testing Event Duplication",
		data_version="2.0",
        id=random_uuid
	), EventGridEvent(
		event_type="Yazure.Online.Event",
		data={
			"id":random_uuid,
            "name": f"user_two_{random_uuid}"
		},
		subject="Testing Event Duplication",
		data_version="2.0",
        id=random_uuid
	)
])

print(f"id for MessageId is {random_uuid} for the time published event to the EG: {now}", )

# Receive message
# expecting service bus queue's duplicate detection to prevent receiving multiple messages

with ServiceBusClient(
        fully_qualified_namespace=FULLY_QUALIFIED_NAMESPACE,
        credential=DefaultAzureCredential(),
        logging_enable=True) as servicebus_client:
	with servicebus_client:
		receiver = servicebus_client.get_queue_receiver(queue_name=QUEUE_NAME)
		with receiver:
			received_msgs = receiver.receive_messages(max_wait_time=30, max_message_count=5)
			assert len(received_msgs) == 1, f"Expected 1 message but received {len(received_msgs)}"

			for msg in received_msgs:
				
				message = json.loads(str(msg))
				print("Received Message: " + json.dumps(message, indent=2))
				# complete the message so that the message is removed from the queue
				receiver.complete_message(msg)
credential.close()