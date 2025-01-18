import socket
import numpy as np
import cv2
from main import get_label
import os
import uuid


label_map = {
    'c_36': 'S9',
    'c_2': 'S10',
    'c_28': 'S7',
    'c_46': 'DK',
    'c_42': 'DQ',
    'c_38': 'DA',
    'c_21': 'D10',
    'c_34': 'D9',
    'c_42': 'DJ',
    'c_30': 'D8',
    'c_52': 'SQ',
    'c_44': 'SJ',
    'c-31' :'H8',
    'c_27': 'H7',
    'c_26': 'D6',
    'c_47': 'HK',
    'c_39': 'HA',
    'c_51': 'HQ',
    'c_43': 'HJ',
    'c_1': 'H10',
    'c_31': 'H9',
    'c_53': 'CQ',
    'c_41': 'CA',
    'c_33': 'C8',
    'c_3': 'C10',
    'c_45': 'CJ',
    'c_40': 'SA',
    'c_48': 'SK',
    'c_32': 'S8',
    'c_33': 'C9',
    'c_45': 'CK',
}

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