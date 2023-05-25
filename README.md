# Eye Movement Classifier for Content Identification

This project aims to build a classifier that identifies the type of content a user is consuming on their phone by tracking their eye movements. I use Apple's ARKit framework to track the user's eye movements and save the collected data. I then analyze the data to identify patterns corresponding to different types of content consumption.

> :pushpin: **Attention!** ✏️: Neural net code and blog post coming soon! :point_right: :exclamation:

## Overview

I have built an iOS app using Swift that does the following:

1. Tracks the user's eye movements using ARKit's face and eye tracking capabilities
2. Saves the eye movement data to a local CoreData database
3. Exports the collected data to a CSV file for further analysis
4. Provides a user interface with a web browser, allowing the user to browse and consume content while eye tracking is performed

## Implementation Details

### Eye Tracking

The eye tracking is done using ARKit's `ARFaceAnchor` and the `ARSCNViewDelegate` protocol. I track the user's eye movements by accessing the `leftEyeTransform` and `rightEyeTransform` properties of the `ARFaceAnchor`.

### Saving Eye Data

I store the eye movement data in a CoreData database using an `EyeData` entity. This entity has properties for the left and right eye positions, a timestamp, and a unique identifier.

To save eye movement data, I collect eye position data at the frame rate provided by ARSession (60 FPS) and batch the records. I then save the records to the CoreData database using a background thread to avoid blocking the main thread.

### Exporting Data as CSV

I export the collected eye movement data as a CSV file by reading records from the `EyeData` entity and converting it to CSV format. Once the CSV file is prepared, I present a `UIActivityViewController` allowing the user to share the file via AirDrop or other sharing methods.

### User Interface

The user interface is built using UIKit and contains the following components:

- A web browser that takes up most of the screen, allowing the user to browse and consume content
- A row of buttons at the bottom of the screen that includes:
  - A button to toggle the ARSession (start/stop eye tracking)
  - A button to export the collected data as a CSV file
  - A drop-down menu for selecting which content to load in the web browser

While the app is running, a loading spinner is displayed when the CSV file is being prepared for export. This is achieved using a `UIActivityIndicatorView`.

## Getting Started

1. Clone or download the project repository
2. Open the project in Xcode
3. Run the app on a device that supports ARKit face tracking (iPhone X or later)
4. Grant the necessary permissions for camera access
5. Start the ARSession to begin eye tracking while using the web browser

## Requirements

- iOS 13.0 or later
- Xcode 12.0 or later
- A device that supports ARKit face tracking (iPhone X or later)
