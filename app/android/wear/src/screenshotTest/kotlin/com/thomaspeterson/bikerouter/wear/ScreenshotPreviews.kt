package com.thomaspeterson.bikerouter.wear

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.tooling.preview.devices.WearDevices

/**
 * Compose Preview Screenshot Testing entry points. `./gradlew
 * :wear:updateDebugScreenshotTest` renders each @Preview here to a reference
 * PNG (round-watch frame, no emulator), which the CI collects as a store
 * screenshot. These feed deterministic demo snapshots into the stateless
 * [NavigationGlance] overload.
 */
@Preview(
    name = "01-navigation",
    device = WearDevices.LARGE_ROUND,
    showBackground = true,
    backgroundColor = 0xFF000000,
)
@Composable
fun GlanceNavigationPreview() {
    MaterialTheme {
        Scaffold {
            NavigationGlance(
                NavigationSnapshot(
                    direction = TurnDirection.RIGHT,
                    distanceToTurnMeters = 240,
                    remainingKm = 12.4,
                    remainingMinutes = 47,
                    streetName = "Maximilianstraße",
                )
            )
        }
    }
}

@Preview(
    name = "02-arrived",
    device = WearDevices.LARGE_ROUND,
    showBackground = true,
    backgroundColor = 0xFF000000,
)
@Composable
fun GlanceArrivedPreview() {
    MaterialTheme {
        Scaffold {
            NavigationGlance(
                NavigationSnapshot(
                    direction = TurnDirection.ARRIVED,
                    remainingKm = 0.0,
                    remainingMinutes = 0,
                )
            )
        }
    }
}
