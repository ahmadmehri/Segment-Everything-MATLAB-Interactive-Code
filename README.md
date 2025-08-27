# Segment-Everything-MATLAB-Interactive-Code
A advanced MATLAB GUI application for interactive image segmentation using Segment Anything Model (SAM). This tool provides a user-friendly interface for precise object segmentation with multiple selection methods and shape processing capabilities.

Core Functionality

Interactive Image Segmentation: Click on objects to automatically segment them using SAM
Multiple Selection Methods: Choose between Click-Point Based, Distance-Based, or Largest Component selection
Smart Overlap Prevention: Automatically prevents overlapping segments for clean results
Real-time Visual Feedback: See segmentation results immediately with colored boundaries and labels

Advanced Shape Processing

Adjustable Smoothing: Control boundary smoothness with customizable levels (0-10)
Shape Control: Fine-tune convexity/concavity of segmented shapes (-1 to 10)
Boundary Simplification: Optional polygon simplification for cleaner results
Advanced Smoothing: Enhanced morphological and Gaussian smoothing options

User Interface

Modern Scalable GUI: Responsive layout that adapts to different screen sizes
Comprehensive Controls: Intuitive panels for all segmentation parameters
Object Management: Track, list, and manage all segmented objects
Status Monitoring: Real-time feedback on processing status and model state

Import/Export

Multi-format Image Support: JPG, PNG, BMP, TIFF, GIF
Results Export: Save segmentation results and export individual masks
Session Management: Clear individual objects or reset entire sessions

Requirements

MATLAB R2021a or later
Computer Vision Toolbox (required for SAM model)
Image Processing Toolbox

Usage

Run the main function:

matlabSAM_Interactive_GUI()

Load an image using the "Load Image" button or File menu
Wait for the SAM model to load (first-time use may take a moment)
Click on objects in the image to segment them
Adjust segmentation parameters as needed:

Selection Method: Choose how objects are selected from SAM's multiple proposals
Smoothing Level: Control boundary smoothness
Shape Control: Adjust convexity/concavity balance
Processing Options: Enable boundary simplification or advanced smoothing


Export results or save the session when complete

Selection Methods
1. Click-Point Based (Recommended)

Selects the mask that contains the clicked point
Combines area and distance scoring for optimal results
Best for precise object selection

2. Distance-Based Selection

Prioritizes masks closest to the click point
Useful when multiple objects are near the click location
Balances proximity and object size

3. Largest Component Only

Always selects the largest available mask
Useful for segmenting dominant objects in the scene
Combines area and shape compactness metrics

Shape Processing Controls

Smoothing Level (0-10): Higher values create smoother boundaries
Shape Control (-1 to 10):

Negative values: Force convex shapes
0-3: Mostly convex results
4-6: Balanced processing
7+: Preserve concave features


Boundary Simplification: Reduces polygon complexity
Advanced Smoothing: Uses Gaussian-based smoothing methods

File Structure
SAM_Interactive_GUI.m       # Main application file
├── GUI Setup Functions    # Interface creation and layout
├── Image Processing       # SAM integration and mask processing  
├── Selection Methods      # Multiple object selection algorithms
├── Shape Enhancement      # Advanced smoothing and shape control
└── Utility Functions      # Helper functions and callbacks
