# N3ONProduction
the backend of my app N3ON
## 🎯 Project Overview
N3ON is a iOS SwiftUI application featuring rich user experience through real-time chat, location-aware venue advertisement, user-generated media sharing, and AWS Amplify-backed cloud services. It showcases  SwiftUI concepts, Amplify integration, and UX refinement suitable for startup-scale performance.

## 🔐 Features
- **Authentication**: Sign-up/login with Cognito and confirmation flow
- **User Profiles**: Dynamic avatar, audio intros, stats
- **Venue Management**: Add venues, geolocation with MapKit, map pins
- **Media Posting**: Upload and preview images, videos, and audio
- **Chat System**: Real-time messaging using Amplify DataStore
- **Custom Components**: `ImagePicker`, `MixedMediaPicker`, `PulsingAvatarView`, `AudioPlayerView`
- **AWS Integration**:
  - S3 storage for images/audio/video
  - Auth & Identity
  - DataStore for offline-first data model
  - 
## ⚙️ Tech Stack
- **Language**: Swift, SwiftUI, Combine
- **Frameworks**: MapKit, AVFoundation, UIKit (via Representables)
- **Cloud**: AWS Amplify (Cognito, S3, DataStore)
