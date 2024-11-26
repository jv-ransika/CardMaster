import socket
import numpy as np
import cv2
from main import get_label
import os
import uuid

# Server IP and port
SERVER_IP = '192.168.52.31'  # Listen on all available network interfaces
SERVER_PORT = 5005


def receive_image(connection):
    # First, receive the size of the image (sent as 4 bytes)
    image_size_data = connection.recv(4)
    if not image_size_data:
        print("Failed to receive image size.")
        return

    image_size = int.from_bytes(image_size_data, byteorder='little')
    print(f"Receiving image of size {image_size} bytes")

    # Receive the actual image data
    image_data = bytearray()
    while len(image_data) < image_size:
        packet = connection.recv(4096)
        if not packet:
            break
        image_data.extend(packet)

    # Convert to numpy array and decode the image
    np_data = np.frombuffer(image_data, dtype=np.uint8)
    img = cv2.imdecode(np_data, cv2.IMREAD_COLOR)

    if img is not None:
        get_label(img)
        # cv2.imshow("Received Image", img)
        # cv2.waitKey(1)
    else:
        print("Failed to decode image")


def main():
    # Set up TCP server
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.bind((SERVER_IP, SERVER_PORT))
        server_socket.listen()
        print(f"Server listening on {SERVER_IP}:{SERVER_PORT}")

        while True:
            # Wait for a connection from the ESP32
            connection, address = server_socket.accept()
            print(f"Connected by {address}")

            # Receive and display the image
            receive_image(connection)

            # Close connection after receiving one image (can be modified if you want continuous streaming)
            connection.close()
            print("Connection closed")


if __name__ == "__main__":
    main()
    def save_image_with_unique_name(img):
        filename = f"image_{uuid.uuid4().hex}.png"
        os.makedirs("images", exist_ok=True)
        cv2.imwrite(os.path.join("images", filename), img)
        print(f"Image saved as {filename}")