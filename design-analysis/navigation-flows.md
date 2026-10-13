# Navigation flows

Router: `lib/app/router/app_router.dart`. A redirect (`redirect.dart`) keeps each session stage on
its own screens: signed out -> auth screens, onboarding -> `/setup`, signed in -> the tabs.
Tabs are an `indexedStack` (each tab keeps its stack and scroll). Detail screens push over the tabs.

## Sign-in and setup

```mermaid
flowchart LR
  Splash -->|1.5 s| Welcome
  Welcome -->|phone| SignIn[Phone number]
  Welcome -->|Google| Setup
  SignIn -->|10 digits, Send code| OTP
  OTP -->|wrong code| OTP
  OTP -->|123456 in demo| Setup
  Setup --> S1[Name + birthday 18+] --> S2[Gender + show me] --> S3[2+ photos] --> S4[Bio + 3-6 interests] --> S5[Location] --> S6[Verify or skip] --> S7[Done]
  S7 -->|Start discovering| Discover
```

Back: each setup step goes back one step (system back included); the first step leaves the screen.

## Main navigation

```mermaid
flowchart TB
  Discover <--> Matches <--> Chats <--> Profile
  Discover -->|info button| ProfileDetail
  Matches -->|tile| Chat
  Matches -->|Likes you tile, free| PremiumPrompt --> Premium
  Chats -->|row| Chat
  Chat -->|header or menu| ProfileDetail
  Profile --> EditProfile
  Profile --> Settings --> Notifications
  Profile --> Privacy
  Settings --> Privacy
  Profile -->|Go Premium| Premium
```

## Discovery and matching

```mermaid
flowchart LR
  Deck -->|swipe right / like| Like
  Deck -->|swipe left / pass| Pass
  Deck -->|swipe up / super like| Super
  Super -->|free, 2nd one| PremiumPrompt
  Like -->|they liked you| Match[Match overlay]
  Match -->|Send a message| Chat
  Match -->|Keep swiping| Deck
  Deck -->|empty| Empty[Adjust filters] --> Filters --> Deck
```

## Messaging and safety

```mermaid
flowchart LR
  Chat -->|text, photo, voice| Chat
  Chat -->|menu| Menu
  Menu --> ViewProfile
  Menu -->|Report| Reasons --> Toast[Report sent]
  Menu -->|Block| ConfirmBlock --> Chats
  Menu -->|Unmatch| ConfirmUnmatch --> Chats
```

## Subscription

```mermaid
flowchart LR
  Lock[Any Premium lock] --> Prompt[Premium prompt sheet] -->|See Premium| Paywall
  Profile --> Paywall
  Paywall -->|plan, Continue| Confirm[Demo billing sheet] -->|Unlock for demo| Active[Premium active, locks open]
  Paywall -->|close| Back
```

Locks: Likes you (grid is blurred), verified-only filter, Incognito mode, Super Likes beyond the
first. Premium and modal behaviour: the paywall rises from the bottom (full-screen dialog route);
sheets and dialogs use the design system's own routes.
