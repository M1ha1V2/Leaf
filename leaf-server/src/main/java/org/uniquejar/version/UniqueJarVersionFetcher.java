package org.uniquejar.version;

import com.destroystokyo.paper.util.VersionFetcher;
import io.papermc.paper.ServerBuildInfo;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;

/**
 * Version provider for UniqueJar. It never performs a web request: UniqueJar has no update API, and the inherited
 * Leaf fetcher would query (and compare against) another project's builds.
 */
public class UniqueJarVersionFetcher implements VersionFetcher {

    @Override
    public long getCacheTime() {
        return -1; // nothing to cache, the message is built locally
    }

    @Override
    public Component getVersionMessage() {
        return Component.text(
            "You are running " + ServerBuildInfo.buildInfo().asString(ServerBuildInfo.StringRepresentation.VERSION_FULL)
                + ". Update checking is not available for this build.",
            NamedTextColor.GRAY
        );
    }
}
