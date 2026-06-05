package com.thomaspeterson.bikerouter.wear

import app.cash.paparazzi.DeviceConfig
import app.cash.paparazzi.Paparazzi
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import org.junit.Rule
import org.junit.Test

/**
 * Renders the watch navigation glance to PNG via Paparazzi (layoutlib on the
 * JVM — no emulator). `./gradlew :wear:recordPaparazziDebug` writes the images
 * to wear/src/test/snapshots/images/, which the CI collects as store
 * screenshots. Feeds deterministic demo snapshots into the stateless
 * [NavigationGlance] overload.
 */
class PaparazziScreenshotTest {

    @get:Rule
    val paparazzi = Paparazzi(deviceConfig = DeviceConfig.WEAR_OS_SMALL_ROUND)

    @Test
    fun navigation() {
        paparazzi.snapshot {
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
    }

    @Test
    fun arrived() {
        paparazzi.snapshot {
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
    }
}
