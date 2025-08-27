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
