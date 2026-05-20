package com.thomaspeterson.bikerouter.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Scaffold {
                    NavigationGlance()
                }
            }
        }
    }
}

@Composable
private fun NavigationGlance() {
    val snapshot by NavigationStateHolder.state.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 6.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // Unicode arrow glyph standing in for an SF-Symbol-style icon.
        // Avoids pulling in androidx.compose.material:material-icons-
        // extended (~3 MB of vector assets) just for nine maneuvers.
        Text(
            text = directionGlyph(snapshot.direction),
            fontSize = 56.sp,
            color = Color(0xFF6A4A28),
        )

        Text(
            text = formatDistance(snapshot),
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
        )

        if (!snapshot.streetName.isNullOrEmpty()) {
            Text(
                text = snapshot.streetName!!,
                fontSize = 11.sp,
                color = Color(0xFFAAAAAA),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(formatRemainingKm(snapshot), fontSize = 12.sp, color = Color(0xFFAAAAAA))
            Spacer(modifier = Modifier.width(6.dp))
            Text("·", color = Color(0xFFAAAAAA))
            Spacer(modifier = Modifier.width(6.dp))
            Text(formatEta(snapshot), fontSize = 12.sp, color = Color(0xFFAAAAAA))
        }
    }
}

/** Coarse direction → Unicode glyph. The diagonals (↖, ↗) cleanly
 *  express "slight" turns, the standard arrows the harder ones, and
 *  ↺ catches the U-turn case. */
private fun directionGlyph(d: TurnDirection): String = when (d) {
    TurnDirection.IDLE -> "—"
    TurnDirection.STRAIGHT -> "↑"
    TurnDirection.SLIGHT_LEFT -> "↖"
    TurnDirection.LEFT -> "←"
    TurnDirection.SHARP_LEFT -> "↺"
    TurnDirection.U_TURN -> "↻"
    TurnDirection.SLIGHT_RIGHT -> "↗"
    TurnDirection.RIGHT -> "→"
    TurnDirection.SHARP_RIGHT -> "↻"
    TurnDirection.ARRIVED -> "🏁"
}

private fun formatDistance(s: NavigationSnapshot): String {
    if (s.direction == TurnDirection.ARRIVED) return "Ziel"
    if (s.direction == TurnDirection.IDLE) return "—"
    val m = s.distanceToTurnMeters
    if (m < 1000) return "$m m"
    return String.format(Locale.GERMAN, "%.1f km", m / 1000.0)
}

private fun formatRemainingKm(s: NavigationSnapshot): String {
    if (s.remainingKm <= 0) return ""
    return String.format(Locale.GERMAN, "%.1f km", s.remainingKm)
}

private fun formatEta(s: NavigationSnapshot): String {
    val m = s.remainingMinutes
    if (m <= 0) return ""
    if (m < 60) return "$m min"
    return String.format(Locale.GERMAN, "%d:%02d h", m / 60, m % 60)
}
