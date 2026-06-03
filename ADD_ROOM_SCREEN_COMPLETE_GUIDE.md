# Add Room Screen - Complete Guide 🏨

## Overview
The "Add Room" screen allows hotel owners to create new room types with detailed information, pricing, amenities, images, and videos.

---

## Complete Field List

### 1. BASIC INFORMATION 📋

#### Room Type Name ⭐ REQUIRED
- **Field**: Text input
- **Example**: "Deluxe Room", "Superior Suite", "Executive Room"
- **Validation**: Required
- **Purpose**: Display name for this room type

#### Description
- **Field**: Multi-line text (3 lines)
- **Example**: "Spacious room with modern amenities and city view"
- **Validation**: Optional
- **Purpose**: Detailed description of the room

---

### 2. PRICING 💰

#### Base Price ⭐ REQUIRED
- **Field**: Number input
- **Label**: "Base Price (₹)"
- **Hint**: "Weekday price"
- **Validation**: Required
- **Purpose**: Standard weekday price per night

#### Weekend Price
- **Field**: Number input
- **Label**: "Weekend Price (₹)"
- **Hint**: "Friday-Sunday price"
- **Validation**: Optional
- **Purpose**: Special pricing for weekends
- **Default**: Uses base price if not specified

---

### 3. CAPACITY 👥

#### Max Adults ⭐ REQUIRED
- **Field**: Number input
- **Icon**: Person icon
- **Validation**: Required
- **Purpose**: Maximum number of adults allowed

#### Max Children ⭐ REQUIRED
- **Field**: Number input
- **Icon**: Child care icon
- **Validation**: Required
- **Purpose**: Maximum number of children allowed

---

### 4. ROOM DETAILS 🛏️

#### Bed Type
- **Field**: Dropdown
- **Options**:
  - KING
  - QUEEN
  - TWIN
  - DOUBLE
  - SINGLE
- **Default**: King
- **Purpose**: Type of bed in the room

#### Room Size ⭐ REQUIRED
- **Field**: Number input
- **Label**: "Room Size (sq ft)"
- **Validation**: Required
- **Purpose**: Room area in square feet

#### View Type
- **Field**: Dropdown
- **Options**:
  - CITY
  - GARDEN
  - MOUNTAIN
  - LAKE
  - SEA
  - POOL
- **Default**: City
- **Purpose**: View from the room

#### Total Rooms of This Type ⭐ REQUIRED
- **Field**: Number input
- **Hint**: "How many rooms of this type?"
- **Validation**: Required
- **Purpose**: Number of rooms available of this type

---

### 5. ADDITIONAL OPTIONS ⚙️

#### Smoking Allowed
- **Field**: Switch toggle
- **Default**: OFF (false)
- **Purpose**: Whether smoking is permitted

#### Extra Bed Available
- **Field**: Switch toggle
- **Default**: OFF (false)
- **Purpose**: Can an extra bed be added?

#### Extra Bed Price (conditional)
- **Field**: Number input
- **Shows**: Only when "Extra Bed Available" is ON
- **Label**: "Extra Bed Price (₹)"
- **Purpose**: Additional charge for extra bed

---

### 6. HOURLY BOOKING ⏰

#### Enable Hourly Booking
- **Field**: Switch toggle
- **Default**: OFF (false)
- **Subtitle**: "Guests can book for a few hours instead of full day"
- **Purpose**: Allow short-term hourly bookings

#### Hourly Price (conditional) ⭐
- **Field**: Number input
- **Shows**: Only when hourly booking is enabled
- **Label**: "Hourly Price (₹)"
- **Hint**: "Price per hour"
- **Validation**: Required when hourly booking is enabled
- **Purpose**: Price per hour for hourly bookings

#### Min Hours (conditional)
- **Field**: Number input
- **Shows**: Only when hourly booking is enabled
- **Default**: 1
- **Hint**: "Minimum booking hours"
- **Purpose**: Minimum hours guest must book

#### Max Hours (conditional)
- **Field**: Number input
- **Shows**: Only when hourly booking is enabled
- **Default**: 12
- **Hint**: "Maximum booking hours"
- **Purpose**: Maximum hours guest can book

---

### 7. ROOM IMAGES 📸

#### Image Upload
- **Field**: Multiple image picker
- **Recommendation**: 5-10 images
- **Features**:
  - Add multiple images at once
  - Preview thumbnails (120x120px)
  - Remove individual images
  - Clear all images
- **Display**: Horizontal scrollable list
- **Actions**:
  - "Add Images" button
  - "Add More Images" (if images exist)
  - "Clear" button (red, removes all)
- **Purpose**: Showcase the room type

---

### 8. ROOM VIDEO TOUR 🎥

#### Video Upload
- **Field**: Video file picker
- **Limit**: Maximum 15 seconds
- **Button**: "Upload Video (15s max)"
- **Display**: Shows count of selected videos
- **Purpose**: Short video tour of the room

#### Video Link
- **Field**: URL input (dialog)
- **Supported**: YouTube, Vimeo
- **Button**: "Add Video Link"
- **Display**: Shows URL with link icon
- **Purpose**: Embed external video tour

#### Video Features:
- Can upload local video OR add link
- Shows count: "X video(s) selected"
- Remove button for each
- Green indicator for uploaded videos
- Blue indicator for video links

---

### 9. AMENITIES ✨

#### Amenity Selection
- **Field**: Multi-select chips
- **Display**: Wrap layout (multiple rows)
- **Selection**: Tap to toggle on/off

#### Available Amenities (15 total):
1. **WIFI** - Wireless internet
2. **AC** - Air conditioning
3. **TV** - Television
4. **MINIBAR** - Mini refrigerator with drinks
5. **SAFE** - In-room safe
6. **HAIRDRYER** - Hair dryer
7. **BATHTUB** - Bathtub in bathroom
8. **SHOWER** - Shower in bathroom
9. **BALCONY** - Private balcony
10. **LOUNGE** - Seating area
11. **DESK** - Work desk
12. **COFFEE MAKER** - Coffee/tea maker
13. **REFRIGERATOR** - Full-size fridge
14. **IRON** - Iron and ironing board
15. **TELEPHONE** - Room telephone

---

## Data Structure Sent to API

### API Endpoint:
```
POST /store-room-type
```

### Request Body:
```json
{
  "hotel_id": "8",
  "name": "Deluxe Room",
  "description": "Spacious room with modern amenities",
  "base_price": 2500.0,
  "weekend_price": 3000.0,
  "max_adults": 2,
  "max_children": 1,
  "bed_type": "king",
  "room_size_sqft": 350,
  "view_type": "city",
  "is_smoking": false,
  "extra_bed_available": true,
  "extra_bed_price": 500.0,
  "total_rooms": 5,
  "amenities": ["wifi", "ac", "tv", "minibar", "safe"]
}
```

### Media Upload (After Room Creation):

**Images:**
```
POST /room-types/{roomTypeId}/media/images
Content-Type: multipart/form-data

Fields:
  category: "rooms"
  images[]: file1.jpg
  images[]: file2.jpg
  images[]: file3.jpg
```

**Videos:**
```
POST /room-types/{roomTypeId}/media/video
Content-Type: multipart/form-data

Fields:
  title: "Deluxe Room Tour"
  is_primary: "1" (first video) or "0"
  video: file.mp4 (max 15 seconds)
```

**Video Link:**
```
POST /room-types/{roomTypeId}/media/video-link
Content-Type: application/json

Body:
{
  "video_url": "https://youtube.com/watch?v=...",
  "title": "Deluxe Room Virtual Tour",
  "type": "youtube" or "vimeo",
  "is_primary": true or false
}
```

---

## Validation Rules

### Required Fields (7):
1. ✅ Room Type Name
2. ✅ Base Price
3. ✅ Max Adults
4. ✅ Max Children
5. ✅ Room Size
6. ✅ Total Rooms
7. ✅ Hourly Price (only if hourly booking enabled)

### Optional Fields:
- Description
- Weekend Price
- Extra Bed Price
- Min/Max Hours
- Images
- Videos
- Video Links
- Amenities

### Conditional Requirements:
- **Extra Bed Price**: Required if "Extra Bed Available" is ON
- **Hourly Price**: Required if "Enable Hourly Booking" is ON
- **Min/Max Hours**: Only shown if hourly booking is enabled

---

## User Flow

### Step-by-Step Process:

```
1. User navigates to Rooms → Add Room
   ↓
2. Fills Basic Information
   - Room Type Name ⭐
   - Description
   ↓
3. Sets Pricing
   - Base Price ⭐
   - Weekend Price (optional)
   ↓
4. Defines Capacity
   - Max Adults ⭐
   - Max Children ⭐
   ↓
5. Specifies Room Details
   - Bed Type (dropdown)
   - Room Size ⭐
   - View Type (dropdown)
   - Total Rooms ⭐
   ↓
6. Configures Additional Options
   - Smoking Allowed (toggle)
   - Extra Bed Available (toggle)
     → Extra Bed Price (if enabled)
   ↓
7. Sets Hourly Booking (optional)
   - Enable Hourly Booking (toggle)
     → Hourly Price ⭐
     → Min Hours
     → Max Hours
   ↓
8. Adds Room Images (optional)
   - Select multiple images
   - Preview and remove
   ↓
9. Adds Video Tour (optional)
   - Upload video (15s max) OR
   - Add YouTube/Vimeo link
   ↓
10. Selects Amenities (optional)
    - Tap chips to select
    - Multiple selection allowed
   ↓
11. Clicks "Add Room Type"
   ↓
12. System:
    - Validates required fields
    - Gets hotel ID
    - Creates room type
    - Uploads images (if any)
    - Uploads videos (if any)
    - Adds video link (if any)
   ↓
13. Shows success message
    - "Room type created with X media file(s)"
   ↓
14. Returns to Rooms list
```

---

## Features & Capabilities

### Image Management:
- ✅ Multiple image selection
- ✅ Preview thumbnails
- ✅ Individual image removal
- ✅ Clear all images
- ✅ Horizontal scroll view
- ✅ Recommended: 5-10 images

### Video Management:
- ✅ Upload local video (max 15 seconds)
- ✅ Add YouTube link
- ✅ Add Vimeo link
- ✅ Multiple videos supported
- ✅ Primary video flag
- ✅ Remove videos individually

### Pricing Flexibility:
- ✅ Weekday pricing
- ✅ Weekend pricing
- ✅ Extra bed pricing
- ✅ Hourly pricing
- ✅ Min/max hour limits

### Amenity Selection:
- ✅ 15 predefined amenities
- ✅ Multi-select interface
- ✅ Visual chip selection
- ✅ Easy toggle on/off

---

## Success Scenarios

### Scenario 1: Basic Room (Minimum Fields)
```
✅ Room Type Name: "Standard Room"
✅ Base Price: 1500
✅ Max Adults: 2
✅ Max Children: 1
✅ Room Size: 250
✅ Total Rooms: 10

Result: Room created successfully
```

### Scenario 2: Deluxe Room with Media
```
✅ All basic fields
✅ Weekend Price: 2000
✅ 8 room images
✅ 1 video tour (10 seconds)
✅ 5 amenities selected

Result: Room type created with 9 media files
```

### Scenario 3: Hourly Booking Room
```
✅ All basic fields
✅ Enable Hourly Booking: ON
✅ Hourly Price: 300
✅ Min Hours: 2
✅ Max Hours: 6

Result: Room with hourly booking enabled
```

---

## Error Handling

### Common Errors:

**1. Missing Required Fields**
- Shows validation error
- Highlights missing fields
- Cannot submit until fixed

**2. Hotel Not Found**
- Message: "Hotel not found. Please register your hotel first."
- User must register hotel before adding rooms

**3. Image Upload Failed**
- Room is still created
- Images fail silently
- Can add images later

**4. Video Upload Failed**
- Room is still created
- Videos fail silently
- Can add videos later

**5. Invalid Video Duration**
- Only videos ≤15 seconds accepted
- Shows error if too long

---

## Tips for Hotel Owners

### Best Practices:

**Images:**
- Upload 5-10 high-quality images
- Show bed, bathroom, view, amenities
- Use good lighting
- Clean and tidy room

**Videos:**
- Keep under 15 seconds
- Show room walkthrough
- Highlight key features
- Use stable camera

**Pricing:**
- Set competitive base price
- Weekend price 10-20% higher
- Extra bed price reasonable
- Hourly price for short stays

**Amenities:**
- Select all available amenities
- Be honest about what's included
- More amenities = more bookings

---

## Summary

### Total Fields: 25+
- **Required**: 7 fields
- **Optional**: 18+ fields
- **Conditional**: 3 fields

### Media Support:
- **Images**: Unlimited (recommended 5-10)
- **Videos**: Multiple (max 15s each)
- **Video Links**: YouTube, Vimeo

### Amenities: 15 options

### Pricing Options: 4 types
- Base price
- Weekend price
- Extra bed price
- Hourly price

---

**Status**: ✅ Fully Functional
**Location**: Owner Mode → Rooms → Add Room
**API**: `/store-room-type`
**Last Updated**: 2026-04-20
