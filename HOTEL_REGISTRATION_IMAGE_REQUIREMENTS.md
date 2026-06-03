# Hotel Registration - Image Requirements 📸

## Overview
During hotel registration (Step 3 of 4), hotel owners need to upload photos to showcase their property. This document outlines all image requirements.

## Image Categories

### 1. Hotel Exterior Photo ⭐ REQUIRED
**Purpose**: Show the exterior view of your hotel

**Details**:
- **Status**: ✅ REQUIRED (Cannot proceed without this)
- **Quantity**: 1 photo
- **Description**: Front view or main entrance of the hotel building
- **Why Required**: First impression for potential guests

**Technical Specs**:
- Max Width: 800px
- Max Height: 600px
- Image Quality: 80%
- Format: JPEG/PNG
- Source: Gallery/Camera

**UI Behavior**:
- Shows placeholder with "Tap to upload exterior photo"
- Blue border when photo is uploaded
- Remove button (X) appears after upload
- "Required" label displayed in red

---

### 2. Reception Photo ⚪ OPTIONAL
**Purpose**: Show your hotel reception area

**Details**:
- **Status**: ⚪ OPTIONAL
- **Quantity**: 1 photo
- **Description**: Front desk, lobby, or check-in area
- **Why Useful**: Shows professionalism and welcoming atmosphere

**Technical Specs**:
- Max Width: 800px
- Max Height: 600px
- Image Quality: 80%
- Format: JPEG/PNG
- Source: Gallery/Camera

**UI Behavior**:
- Shows placeholder with "Tap to upload reception photo"
- Grey border when empty
- Remove button (X) appears after upload
- No "Required" label

---

### 3. Hotel Gallery Photos ⚪ OPTIONAL
**Purpose**: Add multiple photos of rooms, amenities, and facilities

**Details**:
- **Status**: ⚪ OPTIONAL
- **Quantity**: Up to 5 photos
- **Description**: Rooms, restaurant, pool, gym, common areas, etc.
- **Why Useful**: Comprehensive view of property features

**Technical Specs**:
- Max Width: 800px (per photo)
- Max Height: 600px (per photo)
- Image Quality: 80%
- Format: JPEG/PNG
- Source: Gallery/Camera

**UI Behavior**:
- 3-column grid layout
- Shows "Add Photo" button when < 5 photos
- Counter shows "X/5 photos added"
- Each photo has remove button (X)
- Can add photos one by one

---

## Image Upload Flow

### Step-by-Step Process:

```
1. User navigates to Step 3 (Photos)
   ↓
2. Sees three sections:
   - Hotel Exterior Photo (Required) ⭐
   - Reception Photo (Optional)
   - Hotel Gallery (Optional, up to 5)
   ↓
3. Taps on photo placeholder
   ↓
4. Device gallery opens
   ↓
5. User selects photo
   ↓
6. Photo is compressed and displayed
   ↓
7. User can remove and re-upload if needed
   ↓
8. "Continue" button enabled only when exterior photo is uploaded
   ↓
9. User proceeds to Step 4 (Agreements)
   ↓
10. On final submission, all photos are uploaded to backend
```

---

## Technical Implementation

### Image Picker Configuration:
```dart
final XFile? image = await _picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 800,
  maxHeight: 600,
  imageQuality: 80,
);
```

### Image Storage:
- **Local**: Stored as `File` objects during registration
- **Backend**: Uploaded after hotel creation via `/hotel-owner/media/images`

### Upload Format:
```
POST /hotel-owner/media/images
Content-Type: multipart/form-data

Fields:
  hotel_id: {hotelId}
  images[]: exterior.jpg
  images[]: reception.jpg
  images[]: gallery1.jpg
  images[]: gallery2.jpg
  images[]: gallery3.jpg
```

---

## Validation Rules

### Required Validation:
- ✅ At least 1 exterior photo MUST be uploaded
- ❌ Cannot proceed to Step 4 without exterior photo
- ⚪ Reception and gallery photos are optional

### File Validation:
- ✅ Accepts JPEG and PNG formats
- ✅ Automatically compresses to 80% quality
- ✅ Resizes to max 800x600px
- ❌ No file size limit enforced (handled by compression)

### Count Validation:
- Exterior: Exactly 1
- Reception: 0 or 1
- Gallery: 0 to 5

---

## User Experience

### Visual Indicators:

**Empty State**:
- Grey border
- Camera icon
- "Tap to upload" text
- "Required" label (for exterior only)

**Uploaded State**:
- Blue border (exterior/reception)
- Full image preview
- Remove button (X) in top-right corner
- Image covers entire container

**Gallery State**:
- Grid of uploaded photos
- "Add Photo" button when < 5
- Counter: "X/5 photos added"
- Remove button on each photo

### Button States:

**Continue Button**:
- ❌ Disabled (grey) when no exterior photo
- ✅ Enabled (red) when exterior photo uploaded
- Text: "Continue to Agreements"

**Previous Button**:
- Always enabled
- Returns to Step 2 (Location)
- Saves current photo selections

---

## Best Practices for Hotel Owners

### Recommended Photos:

**Exterior Photo** (Required):
- Clear front view of building
- Good lighting (daytime preferred)
- Shows hotel signage/name
- No obstructions

**Reception Photo** (Optional):
- Clean, organized front desk
- Good lighting
- Shows welcoming atmosphere
- Professional appearance

**Gallery Photos** (Optional):
- Room interiors (bed, bathroom)
- Restaurant/dining area
- Pool or recreational facilities
- Gym or fitness center
- Common areas (lobby, corridors)

### Photo Quality Tips:
- Use good lighting
- Clean and tidy spaces
- High resolution images
- Avoid blurry photos
- Show actual property (no stock photos)

---

## Error Handling

### Common Issues:

**1. No Photo Selected**:
- User cancels image picker
- No error shown
- Placeholder remains

**2. Upload Failure**:
- Hotel created successfully
- Images fail to upload
- User sees: "Hotel registered, but images failed to upload. You can add them later from Gallery."
- Can add photos later via Gallery Management

**3. Large File Size**:
- Automatically compressed to 80% quality
- Resized to 800x600px max
- No user intervention needed

---

## Summary

### Minimum Requirements:
- ✅ 1 Exterior Photo (REQUIRED)
- Total: 1 photo minimum

### Maximum Capacity:
- 1 Exterior Photo
- 1 Reception Photo
- 5 Gallery Photos
- Total: 7 photos maximum

### Upload Timing:
- Photos selected during Step 3
- Photos uploaded after hotel creation (Step 4 completion)
- Uploaded to: `/hotel-owner/media/images`

### Fallback:
- If upload fails during registration
- Photos can be added later via:
  - Dashboard → Gallery Management
  - Profile → Gallery

---

**Last Updated**: 2026-04-20
**Status**: ✅ Fully Implemented
**Location**: Step 3 of Hotel Registration Flow
