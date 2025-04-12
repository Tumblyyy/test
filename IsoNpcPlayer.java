package zombie.characters;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;
import knox.event.KnoxEventMainLoop;
import knox.event.npc.NpcFactionManager;
import knox.event.npc.NpcManager;
import knox.event.npc.NpcNetworking;
import knox.event.npc.memory.DeathMemory;
import knox.event.npc.memory.NpcMemories;
import knox.event.npc.memory.NpcMemory.NpcMemoryFeeling;
import knox.event.utils.KnoxEventMathAPI;
import knox.event.utils.NpcDialogueHandler;
import knox.event.utils.NpcFaction;
import knox.event.utils.NpcPreset;
import knox.event.utils.NpcRelationships;
import knox.event.utils.NpcRelationships.DefaultRelation;
import knox.event.utils.NpcRelationships.RelationType;
import knox.event.utils.behaviortree.BanditBehaviorTree;
import knox.event.utils.behaviortree.BehaviorTreeBase;
import knox.event.utils.behaviortree.PoliceBehaviorTree;
import knox.event.utils.behaviortree.SoldierBehaviorTree;
import knox.event.utils.behaviortree.SurvivorBehaviorTree;
import knox.event.utils.waypoints.Waypoint;
import knox.event.utils.waypoints.WaypointHandler;
import org.joml.Vector2i;
import se.krka.kahlua.vm.KahluaTable;
import zombie.GameTime;
import zombie.GameWindow;
import zombie.SandboxOptions;
import zombie.SystemDisabler;
import zombie.ZomboidGlobals;
import zombie.Lua.LuaEventManager;
import zombie.Lua.LuaHookManager;
import zombie.Lua.LuaManager;
import zombie.SandboxOptions.BooleanSandboxOption;
import zombie.SandboxOptions.SandboxOption;
import zombie.SandboxOptions.StringSandboxOption;
import zombie.ai.states.ClimbOverFenceState;
import zombie.ai.states.ClimbOverWallState;
import zombie.ai.states.ClimbThroughWindowState;
import zombie.ai.states.FakeDeadZombieState;
import zombie.ai.states.ForecastBeatenPlayerState;
import zombie.ai.states.PathFindState;
import zombie.ai.states.PlayerFallDownState;
import zombie.ai.states.PlayerHitReactionPVPState;
import zombie.ai.states.PlayerHitReactionState;
import zombie.ai.states.PlayerOnGroundState;
import zombie.ai.states.StaggerBackState;
import zombie.ai.states.SwipeStatePlayer;
import zombie.ai.states.WalkTowardState;
import zombie.characters.BodyDamage.BodyDamage;
import zombie.characters.BodyDamage.BodyPart;
import zombie.characters.BodyDamage.BodyPartType;
import zombie.characters.CharacterTimedActions.BaseAction;
import zombie.characters.CharacterTimedActions.ISNpcBaseAction;
import zombie.characters.IsoPlayer.InputState;
import zombie.characters.IsoPlayer.MoveVars;
import zombie.characters.IsoPlayer.s_performance;
import zombie.characters.SurvivorGroup.JobDescriptor;
import zombie.characters.skills.PerkFactory.Perks;
import zombie.chat.ChatManager;
import zombie.chat.ChatMessage;
import zombie.chat.defaultChats.RangeBasedChat;
import zombie.core.Core;
import zombie.core.PerformanceSettings;
import zombie.core.Rand;
import zombie.core.math.PZMath;
import zombie.core.skinnedmodel.animation.AnimationPlayer;
import zombie.core.utils.UpdateLimit;
import zombie.debug.DebugLog;
import zombie.debug.DebugOptions;
import zombie.input.GameKeyboard;
import zombie.inventory.InventoryItem;
import zombie.inventory.ItemContainer;
import zombie.inventory.types.HandWeapon;
import zombie.inventory.types.InventoryContainer;
import zombie.inventory.types.WeaponType;
import zombie.iso.BuildingDef;
import zombie.iso.IsoCell;
import zombie.iso.IsoDirections;
import zombie.iso.IsoGridSquare;
import zombie.iso.IsoMovingObject;
import zombie.iso.IsoObject;
import zombie.iso.IsoUtils;
import zombie.iso.IsoWorld;
import zombie.iso.LosUtil;
import zombie.iso.Vector2;
import zombie.iso.LosUtil.TestResults;
import zombie.iso.areas.IsoBuilding;
import zombie.iso.areas.SafeHouse;
import zombie.iso.objects.IsoDeadBody;
import zombie.iso.objects.IsoDoor;
import zombie.iso.weather.ClimateManager;
import zombie.network.GameClient;
import zombie.network.GameServer;
import zombie.network.ServerLOS;
import zombie.network.ServerOptions;
import zombie.network.chat.ChatServer;
import zombie.network.chat.ChatType;
import zombie.network.packets.hit.AttackVars;
import zombie.network.packets.hit.HitInfo;
import zombie.util.StringUtils;
import zombie.util.Type;
import zombie.util.list.PZArrayUtil;
import zombie.vehicles.BaseVehicle;
import zombie.vehicles.PathFindBehavior2.BehaviorResult;
import zombie.vehicles.PolygonalMap2.Path;

public class IsoNpcPlayer extends IsoPlayer {
   private UpdateLimit playerUpdateLimit;
   private UpdateLimit playerUpdateReliableLimit;
   private boolean forcePlayerUpdate;
   private UpdateLimit itemSendFrequency;
   public InventoryContainer cachedBackPack;
   public HandWeapon cachedWeapon;
   public HashMap<ItemContainer, ArrayList<InventoryItem>> itemsToAdd;
   public HashMap<ItemContainer, ArrayList<InventoryItem>> itemsToRemove;
   private BehaviorTreeBase tree;
   private final MoveVars currentMoveVars;
   public final zombie.characters.IsoNpcPlayer.PendingNpcControls pendingNpcControls;
   public NpcRelationships relationships;
   public NpcDialogueHandler dialogue;
   public NpcMemories memories;
   private float carefulCutoff;
   private float dangerousCutoff;
   private float lethalCutoff;
   public boolean bIsInMeta;
   public boolean bWasInMeta;
   protected static final int TARGET_SCAN_RADIUS = 10;
   public HashMap<IsoMovingObject, Float> nearByCharacters;
   public HashMap<IsoPlayer, Double> nearByFriendlies;
   public HashSet<IsoZombie> lethalZombieTargets;
   public HashMap<IsoZombie, Double> dangerousZombieTargets;
   public HashMap<IsoZombie, Double> carefulZombieTargets;
   protected HashMap<IsoPlayer, Double> dangerousPlayerTargets;
   public HashMap<IsoPlayer, Double> nearbyPlayerTargets;
   protected HashMap<IsoNpcPlayer, Double> dangerousNpcTargets;
   public HashMap<IsoNpcPlayer, Double> nearbyNpcTargets;
   public HashMap<IsoPlayer, Double> trespasserTargets;
   public HashMap<IsoPlayer, Double> robbingTargets;
   protected IsoGameCharacter closestNpcAttackTarget;
   protected double closestNpcAttackTargetDist;
   protected IsoGameCharacter closestPlayerAttackTarget;
   protected double closestPlayerAttackTargetDist;
   public IsoGameCharacter closestZombieAttackTarget;
   protected double closestZombieAttackTargetDist;
   protected SafeHouse safeHouse;
   protected IsoBuilding safeHouseBuilding;
   public JobDescriptor activeJob;
   private boolean debugNpcEnable;
   private boolean debugTreeEnable;
   private int exceptionThrottle;
   private int invalidDestinationThrottle;
   public static final int ERROR_PRINT_THROTTLE_RELOAD = 100;
   public ArrayList<zombie.characters.IsoNpcPlayer.NpcDamageUpdater> npcUpdaters;
   private boolean wasMovingManually;
   private static String[] maleNpcNames = new String[]{"Griffin", "Tyrone", "Frederick", "Deshawn", "Marques", "Houston", "Orlando", "Wesley", "William", "Tyshawn", "Jay", "Reece", "Aldo", "Brock", "Issac", "Miguel", "Avery", "Seamus", "Franklin", "Soren", "Keshawn", "Sincere", "Lucas", "Simon", "Jeremy", "Marquis", "Jason", "Victor", "Ross", "Jorge", "Colton", "Hugh", "Leo", "Jesse", "Oswaldo", "Jacob", "Talon", "Braydon", "Roy", "Dax", "Kingston", "Jabari", "Joshua", "Jared", "Urijah", "Cordell", "Blaze", "Mauricio", "Alonso", "Rodney", "Erick", "Leonard", "Kamron", "Donavan", "Reagan", "Kamari", "Nelson", "Maddox", "Landyn", "Sammy", "Shaun", "Korbin", "Owen", "Khalil", "Jacoby", "Angel", "Kendrick", "Howard", "Bronson", "Noel", "Cortez", "Erik", "Carmelo", "Moses", "Jonah", "Jairo", "Jayson", "Yair", "Chaim", "Rogelio", "Ryan", "Koen", "Rylan", "Jean", "Jaxson", "Elias", "Dylan", "Dustin", "Gaven", "Ishaan", "Shane", "Killian", "Jakob", "Tanner", "Graham", "Allan", "Eduardo", "Chace", "Jax", "Alvaro", "Saul"};
   private static String[] femaleNpcNames = new String[]{"Alondra", "Laney", "Danielle", "Kadence", "Justice", "Kassandra", "Elsa", "Kasey", "Alexus", "Karli", "Areli", "Caitlyn", "Dulce", "Tiara", "Londyn", "Kaylin", "Luz", "Wendy", "Alisson", "Nayeli", "Maria", "Isabella", "Dominique", "Heidi", "Nathalia", "Diya", "Noemi", "Nevaeh", "Ashly", "Theresa", "Jaylyn", "Asia", "Kyla", "Kyleigh", "Valentina", "Leyla", "Mariyah", "Hayley", "Maren", "Iyana", "Krystal", "Tamara", "Charlie", "Briley", "Ashleigh", "Yasmin", "Mckinley", "Laurel", "Aiyana", "Anaya", "Rhianna", "Jaylene", "Shayna", "Paulina", "Jaelynn", "Isabela", "Milagros", "Gemma", "Paris", "Jaylee", "Cora", "Mara", "Mayra", "Madeline", "Lia", "Kelsey", "Peyton", "Braelyn", "Sarah", "Kaitlin", "Frances", "Annabel", "Madeleine", "Juliana", "Luciana", "Kiley", "Zoey", "Sylvia", "Deanna", "Moriah", "Hana", "Miriam", "Armani", "Trinity", "Naima", "Cali", "Zariah", "Skylar", "Yamilet", "Christine", "Felicity", "Jayleen", "Patience", "Brenna", "Michelle", "Jaslyn", "Jocelyn", "Kendall", "Shania", "Mylee"};
   private static final int VERSION = 195;

   public IsoNpcPlayer() {
      super(IsoWorld.instance.CurrentCell, (SurvivorDesc)null, 0, 0, 0);
      this.playerUpdateLimit = new UpdateLimit(600L);
      this.playerUpdateReliableLimit = new UpdateLimit(2000L);
      this.forcePlayerUpdate = false;
      this.itemSendFrequency = new UpdateLimit(3000L);
      this.itemsToAdd = new HashMap();
      this.itemsToRemove = new HashMap();
      this.tree = null;
      this.currentMoveVars = new MoveVars();
      this.pendingNpcControls = new zombie.characters.IsoNpcPlayer.PendingNpcControls();
      this.relationships = null;
      this.memories = new NpcMemories(this);
      this.carefulCutoff = 6.0F;
      this.dangerousCutoff = 4.0F;
      this.lethalCutoff = 0.8F;
      this.bIsInMeta = false;
      this.bWasInMeta = false;
      this.nearByCharacters = new HashMap();
      this.nearByFriendlies = new HashMap();
      this.lethalZombieTargets = new HashSet();
      this.dangerousZombieTargets = new HashMap();
      this.carefulZombieTargets = new HashMap();
      this.dangerousPlayerTargets = new HashMap();
      this.nearbyPlayerTargets = new HashMap();
      this.dangerousNpcTargets = new HashMap();
      this.nearbyNpcTargets = new HashMap();
      this.trespasserTargets = new HashMap();
      this.robbingTargets = new HashMap();
      this.closestNpcAttackTarget = null;
      this.closestNpcAttackTargetDist = 0.0D;
      this.closestPlayerAttackTarget = null;
      this.closestPlayerAttackTargetDist = 0.0D;
      this.closestZombieAttackTarget = null;
      this.closestZombieAttackTargetDist = 0.0D;
      this.safeHouse = null;
      this.safeHouseBuilding = null;
      this.activeJob = null;
      this.debugNpcEnable = false;
      this.debugTreeEnable = false;
      this.exceptionThrottle = 100;
      this.invalidDestinationThrottle = 100;
      this.npcUpdaters = new ArrayList();
      this.wasMovingManually = false;
      this.setNPC(true);
      this.setCollidable(true);
      this.setAvoidDamage(false);
      this.setUnlimitedEndurance(false);
      this.setNoDamage(false);
      String var10001 = this.descriptor.getForename();
      this.setUsername(var10001 + " " + this.descriptor.getSurname());
      this.setForname(this.descriptor.getForename());
      this.setSurname(this.descriptor.getSurname());
      this.setOnlineID(NpcManager.allocateAvailableId(this));
      this.setFemale(this.descriptor.isFemale());
      this.relationships = new NpcRelationships(this, DefaultRelation.NEUTRAL);
      this.dialogue = new NpcDialogueHandler(this);
      SandboxOption npcPVPAlwaysOn = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.General_NpcPVPAlwaysOn");
      if (npcPVPAlwaysOn instanceof BooleanSandboxOption) {
         BooleanSandboxOption bNpcPVPAlwaysOn = (BooleanSandboxOption)npcPVPAlwaysOn;
         BooleanSandboxOption var4 = (BooleanSandboxOption)npcPVPAlwaysOn;
         if (bNpcPVPAlwaysOn.getValue() && GameServer.bServer) {
            this.getSafety().toggleSafety();
         }
      }

   }

   public IsoNpcPlayer(IsoCell isoCell, SurvivorDesc npcDesc, int x, int y, int z) {
      super(isoCell, npcDesc, x, y, z);
      this.playerUpdateLimit = new UpdateLimit(600L);
      this.playerUpdateReliableLimit = new UpdateLimit(2000L);
      this.forcePlayerUpdate = false;
      this.itemSendFrequency = new UpdateLimit(3000L);
      this.itemsToAdd = new HashMap();
      this.itemsToRemove = new HashMap();
      this.tree = null;
      this.currentMoveVars = new MoveVars();
      this.pendingNpcControls = new zombie.characters.IsoNpcPlayer.PendingNpcControls();
      this.relationships = null;
      this.memories = new NpcMemories(this);
      this.carefulCutoff = 6.0F;
      this.dangerousCutoff = 4.0F;
      this.lethalCutoff = 0.8F;
      this.bIsInMeta = false;
      this.bWasInMeta = false;
      this.nearByCharacters = new HashMap();
      this.nearByFriendlies = new HashMap();
      this.lethalZombieTargets = new HashSet();
      this.dangerousZombieTargets = new HashMap();
      this.carefulZombieTargets = new HashMap();
      this.dangerousPlayerTargets = new HashMap();
      this.nearbyPlayerTargets = new HashMap();
      this.dangerousNpcTargets = new HashMap();
      this.nearbyNpcTargets = new HashMap();
      this.trespasserTargets = new HashMap();
      this.robbingTargets = new HashMap();
      this.closestNpcAttackTarget = null;
      this.closestNpcAttackTargetDist = 0.0D;
      this.closestPlayerAttackTarget = null;
      this.closestPlayerAttackTargetDist = 0.0D;
      this.closestZombieAttackTarget = null;
      this.closestZombieAttackTargetDist = 0.0D;
      this.safeHouse = null;
      this.safeHouseBuilding = null;
      this.activeJob = null;
      this.debugNpcEnable = false;
      this.debugTreeEnable = false;
      this.exceptionThrottle = 100;
      this.invalidDestinationThrottle = 100;
      this.npcUpdaters = new ArrayList();
      this.wasMovingManually = false;
      if (npcDesc.isFemale()) {
         npcDesc.setForename(getRandomFemaleName());
      } else {
         npcDesc.setForename(getRandomMaleName());
      }

      npcDesc.setInstance(this);
      this.setNPC(true);
      this.setCollidable(true);
      this.setAvoidDamage(false);
      this.setUnlimitedEndurance(false);
      this.setNoDamage(false);
      String var10001 = this.descriptor.getForename();
      this.setUsername(var10001 + " " + this.descriptor.getSurname());
      this.setForname(this.descriptor.getForename());
      this.setSurname(this.descriptor.getSurname());
      this.setOnlineID(NpcManager.allocateAvailableId(this));
      this.setFemale(this.descriptor.isFemale());
      this.relationships = new NpcRelationships(this, DefaultRelation.NEUTRAL);
      this.dialogue = new NpcDialogueHandler(this);
      SandboxOption npcPVPAlwaysOn = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.General_NpcPVPAlwaysOn");
      if (npcPVPAlwaysOn instanceof BooleanSandboxOption) {
         BooleanSandboxOption bNpcPVPAlwaysOn = (BooleanSandboxOption)npcPVPAlwaysOn;
         BooleanSandboxOption var9 = (BooleanSandboxOption)npcPVPAlwaysOn;
         if (bNpcPVPAlwaysOn.getValue() && GameServer.bServer) {
            this.getSafety().toggleSafety();
         }
      }

   }

   public IsoNpcPlayer(IsoCell isoCell, SurvivorDesc npcDesc, int x, int y, int z, boolean isFemale) {
      super(isoCell, npcDesc, x, y, z);
      this.playerUpdateLimit = new UpdateLimit(600L);
      this.playerUpdateReliableLimit = new UpdateLimit(2000L);
      this.forcePlayerUpdate = false;
      this.itemSendFrequency = new UpdateLimit(3000L);
      this.itemsToAdd = new HashMap();
      this.itemsToRemove = new HashMap();
      this.tree = null;
      this.currentMoveVars = new MoveVars();
      this.pendingNpcControls = new zombie.characters.IsoNpcPlayer.PendingNpcControls();
      this.relationships = null;
      this.memories = new NpcMemories(this);
      this.carefulCutoff = 6.0F;
      this.dangerousCutoff = 4.0F;
      this.lethalCutoff = 0.8F;
      this.bIsInMeta = false;
      this.bWasInMeta = false;
      this.nearByCharacters = new HashMap();
      this.nearByFriendlies = new HashMap();
      this.lethalZombieTargets = new HashSet();
      this.dangerousZombieTargets = new HashMap();
      this.carefulZombieTargets = new HashMap();
      this.dangerousPlayerTargets = new HashMap();
      this.nearbyPlayerTargets = new HashMap();
      this.dangerousNpcTargets = new HashMap();
      this.nearbyNpcTargets = new HashMap();
      this.trespasserTargets = new HashMap();
      this.robbingTargets = new HashMap();
      this.closestNpcAttackTarget = null;
      this.closestNpcAttackTargetDist = 0.0D;
      this.closestPlayerAttackTarget = null;
      this.closestPlayerAttackTargetDist = 0.0D;
      this.closestZombieAttackTarget = null;
      this.closestZombieAttackTargetDist = 0.0D;
      this.safeHouse = null;
      this.safeHouseBuilding = null;
      this.activeJob = null;
      this.debugNpcEnable = false;
      this.debugTreeEnable = false;
      this.exceptionThrottle = 100;
      this.invalidDestinationThrottle = 100;
      this.npcUpdaters = new ArrayList();
      this.wasMovingManually = false;
      npcDesc.setInstance(this);
      this.relationships = new NpcRelationships(this, DefaultRelation.NEUTRAL);
      this.setForname(npcDesc.getForename());
      this.setSurname(npcDesc.getSurname());
      this.setNPC(true);
      this.setCollidable(true);
      this.setAvoidDamage(false);
      this.setUnlimitedEndurance(false);
      this.setNoDamage(false);
      String var10001 = this.descriptor.getForename();
      this.setUsername(var10001 + " " + this.descriptor.getSurname());
      this.OnlineChunkGridWidth = 13;
      this.setOnlineID(NpcManager.allocateAvailableId(this));
      this.setFemale(this.descriptor.isFemale());
      this.bIsInMeta = true;
      this.dialogue = new NpcDialogueHandler(this);
      SandboxOption npcPVPAlwaysOn = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.General_NpcPVPAlwaysOn");
      if (npcPVPAlwaysOn instanceof BooleanSandboxOption) {
         BooleanSandboxOption bNpcPVPAlwaysOn = (BooleanSandboxOption)npcPVPAlwaysOn;
         BooleanSandboxOption var10 = (BooleanSandboxOption)npcPVPAlwaysOn;
         if (bNpcPVPAlwaysOn.getValue() && GameServer.bServer) {
            this.getSafety().toggleSafety();
         }
      }

   }

   public IsoNpcPlayer(IsoCell isoCell, SurvivorDesc npcDesc, DefaultRelation type, int x, int y, int z, NpcPreset preset) {
      this(isoCell, npcDesc, type, x, y, z, npcDesc.isFemale(), preset);
   }

   public IsoNpcPlayer(IsoCell isoCell, SurvivorDesc npcDesc, DefaultRelation type, int x, int y, int z, boolean isFemale, NpcPreset preset) {
      this(isoCell, npcDesc, x, y, z, isFemale);
      npcDesc.setInstance(this);
      preset.dressNpc(this);
      this.setPreferredWeapon(this.getPrimaryHandItem());
      InventoryContainer backPack = (InventoryContainer)Type.tryCastTo(this.getClothingItem_Back(), InventoryContainer.class);
      if (backPack != null) {
         this.cachedBackPack = backPack;
      }

      this.dialogue = new NpcDialogueHandler(this);
      this.relationships = new NpcRelationships(this, type);
      SandboxOption npcPVPAlwaysOn = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.General_NpcPVPAlwaysOn");
      if (npcPVPAlwaysOn instanceof BooleanSandboxOption) {
         BooleanSandboxOption bNpcPVPAlwaysOn = (BooleanSandboxOption)npcPVPAlwaysOn;
         BooleanSandboxOption var10001 = (BooleanSandboxOption)npcPVPAlwaysOn;
         if (bNpcPVPAlwaysOn.getValue() && GameServer.bServer) {
            this.getSafety().toggleSafety();
         }
      }

   }

   public IsoNpcPlayer(IsoCell isoCell, SurvivorDesc npcDesc, DefaultRelation type, int x, int y, int z, boolean isFemale, NpcPreset preset, String outfit) {
      this(isoCell, npcDesc, x, y, z, isFemale);
      npcDesc.setInstance(this);
      preset.dressNpcWithOutfit(this, outfit);
      this.setPreferredWeapon(this.getPrimaryHandItem());
      this.dialogue = new NpcDialogueHandler(this);
      this.relationships = new NpcRelationships(this, type);
      SandboxOption npcPVPAlwaysOn = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.General_NpcPVPAlwaysOn");
      if (npcPVPAlwaysOn instanceof BooleanSandboxOption) {
         BooleanSandboxOption bNpcPVPAlwaysOn = (BooleanSandboxOption)npcPVPAlwaysOn;
         BooleanSandboxOption var10001 = (BooleanSandboxOption)npcPVPAlwaysOn;
         if (bNpcPVPAlwaysOn.getValue() && GameServer.bServer) {
            this.getSafety().toggleSafety();
         }
      }

   }

   private static String getRandomMaleName() {
      int npcNameIndex = Rand.Next(maleNpcNames.length);
      return maleNpcNames[npcNameIndex];
   }

   private static String getRandomFemaleName() {
      int npcNameIndex = Rand.Next(femaleNpcNames.length);
      return femaleNpcNames[npcNameIndex];
   }

   public boolean getDebugNpcEnable() {
      return this.debugNpcEnable;
   }

   public void setDebugNpcEnable(boolean enable) {
      this.debugNpcEnable = enable;
   }

   public boolean getDebugTreeEnable() {
      return this.debugTreeEnable;
   }

   public void setDebugTreeEnable(boolean enable) {
      this.debugTreeEnable = enable;
   }

   public void debugDumpMemories() {
      this.memories.debugDumpMemories();
   }

   public void attachTree(BehaviorTreeBase tree) {
      this.tree = tree;
   }

   public void detachTree() {
      this.tree = null;
   }

   public BehaviorTreeBase getBehaviorTree() {
      return this.tree;
   }

   public String getGoal() {
      return this.tree.getGoal();
   }

   public String getGoalPretty() {
      String goal = this.getGoal();
      goal = goal.replaceAll("SubTree", "");
      return goal;
   }

   public void setGoal(String goal) {
      if (this.activeJob != null) {
         this.getGroup().groupScheduler.removeNpcJob(this);
      }

      this.tree.setGoal(goal);
   }

   public String getSubGoal() {
      return this.tree.getSubGoal();
   }

   public String getSubGoalPretty() {
      String subGoal = this.getSubGoal();
      subGoal = subGoal.replaceAll("SubTree", "");
      return subGoal;
   }

   public void setSubGoal(String goal) {
      if (this.activeJob != null) {
         this.getGroup().groupScheduler.removeNpcJob(this);
      }

      this.tree.setSubGoal(goal);
   }

   public void moveToF(float x, float y, float z, float offset, boolean forceRestart, boolean checkInside) {
      this.pendingNpcControls.pathObject = null;
      this.pendingNpcControls.moveX = 0.0F;
      this.pendingNpcControls.moveY = 0.0F;
      this.pendingNpcControls.pathX = x;
      this.pendingNpcControls.pathY = y;
      this.pendingNpcControls.pathZ = z;
      this.pendingNpcControls.pathOffset = offset;
      this.pendingNpcControls.bMoveForceRestart = forceRestart;
      this.pendingNpcControls.bCheckInside = checkInside;
      this.pendingNpcControls.bCheckBlocked = false;
   }

   public void moveToObject(IsoObject targetObject, float offset, boolean checkInside) {
      this.pendingNpcControls.moveX = 0.0F;
      this.pendingNpcControls.moveY = 0.0F;
      this.pendingNpcControls.pathX = -1.0F;
      this.pendingNpcControls.pathY = -1.0F;
      this.pendingNpcControls.pathZ = -1.0F;
      this.pendingNpcControls.pathObject = targetObject;
      this.pendingNpcControls.bMoveForceRestart = false;
      this.pendingNpcControls.bCheckInside = checkInside;
      this.pendingNpcControls.pathOffset = offset;
      this.pendingNpcControls.bCheckBlocked = true;
   }

   public void manualMovement(Vector2 dir) {
      this.pendingNpcControls.pathX = -1.0F;
      this.pendingNpcControls.pathY = -1.0F;
      this.pendingNpcControls.pathZ = -1.0F;
      this.pendingNpcControls.pathOffset = -1.0F;
      this.pendingNpcControls.bMoveForceRestart = false;
      this.pendingNpcControls.bCheckInside = false;
      this.pendingNpcControls.bCheckBlocked = false;
      this.pendingNpcControls.pathObject = null;
      this.pendingNpcControls.moveX = dir.x;
      this.pendingNpcControls.moveY = dir.y;
   }

   public void stopMovement() {
      this.pendingNpcControls.pathX = -1.0F;
      this.pendingNpcControls.pathY = -1.0F;
      this.pendingNpcControls.pathZ = -1.0F;
      this.pendingNpcControls.pathOffset = -1.0F;
      this.pendingNpcControls.bMoveForceRestart = false;
      this.pendingNpcControls.bCheckInside = false;
      this.pendingNpcControls.bCheckBlocked = false;
      this.pendingNpcControls.pathObject = null;
      this.pendingNpcControls.moveX = 0.0F;
      this.pendingNpcControls.moveY = 0.0F;
   }

   public boolean climbOverWall(IsoDirections isoDirections) {
      if (!this.canClimbOverWall(isoDirections)) {
         return false;
      } else {
         this.dropHeavyItems();
         ClimbOverWallState.instance().setParams(this, isoDirections);
         this.actionContext.reportEvent("EventClimbWall");
         return true;
      }
   }

   public void sitDown() {
      if (!this.isJustMoved()) {
         this.reportEvent("EventSitOnGround");
      }

   }

   public void setNpcGroup(SurvivorGroup group) {
      this.getDescriptor().group = group;
   }

   public boolean isPlayerControlled() {
      return this.getGroup() != null ? this.getGroup().isPlayerGroup() : false;
   }

   public IsoGameCharacter getClosestAttackTarget() {
      float closestTargetDist = Float.MAX_VALUE;
      float dist = Float.MAX_VALUE;
      IsoGameCharacter actualTarget = null;
      if (this.closestZombieAttackTarget != null) {
         dist = this.DistToProper(this.closestZombieAttackTarget);
         if (dist < closestTargetDist) {
            actualTarget = this.closestZombieAttackTarget;
         }
      }

      if (this.closestNpcAttackTarget != null) {
         dist = this.DistToProper(this.closestNpcAttackTarget);
         if (dist < closestTargetDist) {
            actualTarget = this.closestNpcAttackTarget;
         }
      }

      if (this.closestPlayerAttackTarget != null) {
         dist = this.DistToProper(this.closestPlayerAttackTarget);
         if (dist < closestTargetDist) {
            actualTarget = this.closestPlayerAttackTarget;
         }
      }

      return actualTarget;
   }

   public IsoPlayer getClosestRobbingTarget() {
      IsoPlayer closest = null;
      Double closestDist = Double.MAX_VALUE;
      Iterator var4 = this.robbingTargets.entrySet().iterator();

      while(var4.hasNext()) {
         Entry<IsoPlayer, Double> entry = (Entry)var4.next();
         if ((Double)entry.getValue() < closestDist) {
            closest = (IsoPlayer)entry.getKey();
            closestDist = (Double)entry.getValue();
         }
      }

      return closest;
   }

   public Vector2 getAverageDangerousTargetsPosition() {
      Vector2 avgPos = new Vector2();
      int elements = 0;
      Iterator var4 = this.dangerousZombieTargets.entrySet().iterator();

      Entry entry;
      while(var4.hasNext()) {
         entry = (Entry)var4.next();
         if ((Double)entry.getValue() < 4.0D) {
            avgPos.x += ((IsoZombie)entry.getKey()).getX();
            avgPos.y += ((IsoZombie)entry.getKey()).getY();
            ++elements;
         }
      }

      var4 = this.dangerousNpcTargets.entrySet().iterator();

      while(var4.hasNext()) {
         entry = (Entry)var4.next();
         if ((Double)entry.getValue() < 4.0D) {
            avgPos.x += ((IsoNpcPlayer)entry.getKey()).getX();
            avgPos.y += ((IsoNpcPlayer)entry.getKey()).getY();
            ++elements;
         }
      }

      var4 = this.dangerousPlayerTargets.entrySet().iterator();

      while(var4.hasNext()) {
         entry = (Entry)var4.next();
         if ((Double)entry.getValue() < 4.0D) {
            avgPos.x += ((IsoPlayer)entry.getKey()).getX();
            avgPos.y += ((IsoPlayer)entry.getKey()).getY();
            ++elements;
         }
      }

      if (elements > 0) {
         avgPos.x /= (float)elements;
         avgPos.y /= (float)elements;
      } else {
         avgPos.x = this.getX();
         avgPos.y = this.getX();
         Vector2 moveVec = new Vector2(1.0F, 0.0F);
         moveVec.setLength(3.0F);
         moveVec.rotate(IsoDirections.getRandom().toAngle());
         avgPos.add(moveVec);
      }

      return avgPos;
   }

   private void processTarget(IsoMovingObject obj, double dist) {
      if (obj instanceof IsoZombie || obj instanceof IsoPlayer) {
         boolean canSee = this.CanSee(obj);
         boolean sameBuilding = this.getBuilding() != null && this.getBuilding() == obj.getBuilding();
         boolean trespasser = false;
         if (obj.square != null) {
            trespasser = canSee && this.getSafeHouseBuildingDef() != null && obj.square.getBuilding() != null && obj.square.getBuilding().getDef() == this.getSafeHouseBuildingDef();
         }

         if (canSee) {
            if (obj instanceof IsoZombie) {
               IsoZombie zombie = (IsoZombie)obj;
               IsoZombie var10001 = (IsoZombie)obj;
               if (zombie.isAlive()) {
                  if (dist <= 10.0D && zombie.getCurrentSquare() != null && KnoxEventMathAPI.bresenHamLineAlgo(this.getCurrentSquare(), zombie.getCurrentSquare()).size() > 0) {
                     return;
                  }

                  if (dist <= (double)this.carefulCutoff) {
                     this.carefulZombieTargets.put(zombie, dist);
                  }

                  if (zombie.getTarget() == this && dist <= (double)this.dangerousCutoff) {
                     this.dangerousZombieTargets.put(zombie, dist);
                  }

                  if (zombie.getTarget() == this && dist <= (double)this.lethalCutoff) {
                     this.lethalZombieTargets.add(zombie);
                  }

                  if (dist <= 10.0D && dist < this.closestZombieAttackTargetDist && !sameBuilding) {
                     this.closestZombieAttackTarget = zombie;
                     this.closestZombieAttackTargetDist = dist;
                  }

                  if (dist <= 10.0D && dist < this.closestZombieAttackTargetDist && sameBuilding) {
                     this.closestZombieAttackTarget = zombie;
                     this.closestZombieAttackTargetDist = dist;
                  }

                  return;
               }
            }

            if (obj instanceof IsoNpcPlayer) {
               IsoNpcPlayer npc = (IsoNpcPlayer)obj;
               IsoNpcPlayer var35 = (IsoNpcPlayer)obj;
               if (npc.isAlive()) {
                  NpcFaction var28 = NpcFactionManager.getFactionFromNpc(this);
                  if (var28 instanceof NpcFaction) {
                     NpcFaction faction = (NpcFaction)var28;
                     NpcFaction var42 = (NpcFaction)var28;
                     NpcFaction var30 = NpcFactionManager.getFactionFromNpc(npc);
                     if (var30 instanceof NpcFaction) {
                        NpcFaction npcFaction = (NpcFaction)var30;
                        var42 = (NpcFaction)var30;
                        if (faction == npcFaction) {
                           return;
                        }
                     }
                  }

                  boolean shouldAttack = this.getGroup() != null && this.getGroup().groupIsHostileTo(npc);
                  if (dist < 25.0D && shouldAttack) {
                     this.nearbyPlayerTargets.put(npc, dist);
                  }

                  int relationship = this.relationships.getRelationship(npc);
                  if (trespasser && npc.getGroup() != this.getGroup() && relationship <= 0) {
                  }

                  if (shouldAttack) {
                     if (this.relationships.getRelationship(npc) > -75) {
                        this.relationships.setRelationship(npc, -75);
                     }

                     this.dangerousNpcTargets.put(npc, dist);
                     if (dist < this.closestNpcAttackTargetDist && dist < 15.0D) {
                        this.closestNpcAttackTarget = npc;
                        this.closestNpcAttackTargetDist = dist;
                        return;
                     }
                  } else if (this.getGroup() != null && this.getGroup().getGroupMembers().contains(npc)) {
                     this.nearByFriendlies.put(npc, dist);
                     return;
                  }

                  return;
               }
            }

            if (obj instanceof IsoPlayer) {
               IsoPlayer player = (IsoPlayer)obj;
               IsoPlayer var37 = (IsoPlayer)obj;
               if (player.isAlive()) {
                  if (player.isGodMod()) {
                     return;
                  }

                  if (dist < 25.0D) {
                     this.nearbyPlayerTargets.put(player, dist);
                  }

                  int relationship = this.relationships.getRelationship(player);
                  trespasser &= player.getGroup() != this.getGroup() && relationship <= 50 && relationship > -75;
                  if (this.isPlayerControlled()) {
                     boolean var38;
                     label203: {
                        Faction var16 = Faction.getPlayerFaction(player);
                        if (var16 instanceof Faction) {
                           Faction playerFaction = (Faction)var16;
                           Faction var10002 = (Faction)var16;
                           Faction var17 = Faction.getPlayerFaction(this.getGroupLeader());
                           if (var17 instanceof Faction) {
                              Faction groupFaction = (Faction)var17;
                              var10002 = (Faction)var17;
                              if (playerFaction == groupFaction) {
                                 var38 = false;
                                 break label203;
                              }
                           }
                        }

                        var38 = true;
                     }

                     trespasser &= var38;
                  }

                  if (trespasser) {
                     this.trespasserTargets.put(player, dist);
                  }

                  if (player.getDotWithForwardDirection(this.getX(), this.getY()) > 0.9F && relationship <= 0 && dist <= 7.0D) {
                     InventoryItem var31 = player.getPrimaryHandItem();
                     if (var31 instanceof HandWeapon) {
                        HandWeapon weapon = (HandWeapon)var31;
                        HandWeapon var39 = (HandWeapon)var31;
                        if (weapon.isRanged() && player.isAiming() && player.getGroup() != this.getGroup()) {
                           this.robbingTargets.put(player, dist);
                        }
                     }
                  }

                  SandboxOption militaryIgnoreFactions = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.General_MilitaryIgnorePlayerFactions");
                  if (this.getBehaviorTree() instanceof SoldierBehaviorTree && militaryIgnoreFactions instanceof StringSandboxOption) {
                     StringSandboxOption ignoreFactionsOption = (StringSandboxOption)militaryIgnoreFactions;
                     StringSandboxOption var40 = (StringSandboxOption)militaryIgnoreFactions;
                     String var20 = ignoreFactionsOption.getValue();
                     if (var20 instanceof String) {
                        String ignoreFactions = (String)var20;
                        String var41 = (String)var20;
                        String[] factions = ignoreFactions.split(",");
                        Faction playerFaction = Faction.getPlayerFaction(player.getUsername());
                        String[] var26 = factions;
                        int var25 = factions.length;

                        for(int var24 = 0; var24 < var25; ++var24) {
                           String faction = var26[var24];
                           if (playerFaction != null && playerFaction.getName().equals(faction)) {
                              this.relationships.setRelationship(player, 50);
                              return;
                           }
                        }
                     }
                  }

                  if (this.getGroup() != null && this.getGroup().groupIsHostileTo(player)) {
                     if (this.relationships.getRelationship(player) > -75) {
                        this.relationships.setRelationship(player, -75);
                     }

                     this.dangerousPlayerTargets.put(player, dist);
                     if (dist < this.closestPlayerAttackTargetDist && dist < 15.0D) {
                        this.closestPlayerAttackTarget = player;
                        this.closestPlayerAttackTargetDist = dist;
                     }
                  } else if (this.getGroup() != null && this.getGroup().isLeader(player.getDescriptor())) {
                     this.nearByFriendlies.put(player, dist);
                  }
               }
            }

         }
      }
   }

   private void findTargets() {
      this.closestNpcAttackTarget = null;
      this.closestPlayerAttackTarget = null;
      this.closestZombieAttackTarget = null;
      this.dangerousNpcTargets.clear();
      this.nearbyNpcTargets.clear();
      this.dangerousPlayerTargets.clear();
      this.nearbyPlayerTargets.clear();
      this.nearByFriendlies.clear();
      this.carefulZombieTargets.clear();
      this.dangerousZombieTargets.clear();
      this.lethalZombieTargets.clear();
      this.trespasserTargets.clear();
      this.robbingTargets.clear();
      this.closestNpcAttackTargetDist = Double.MAX_VALUE;
      this.closestPlayerAttackTargetDist = Double.MAX_VALUE;
      this.closestZombieAttackTargetDist = Double.MAX_VALUE;
      if (this.square != null) {
         if (GameServer.bServer) {
            Iterator var2 = this.nearByCharacters.entrySet().iterator();

            while(true) {
               Entry entry;
               IsoMovingObject obj;
               do {
                  if (!var2.hasNext()) {
                     return;
                  }

                  entry = (Entry)var2.next();
                  obj = (IsoMovingObject)entry.getKey();
               } while(!(obj instanceof IsoZombie) && !(obj instanceof IsoPlayer));

               this.processTarget(obj, (double)(Float)entry.getValue());
            }
         } else {
            for(int z = 0; z <= (int)this.getZ(); ++z) {
               for(int y = this.square.y - 20; y <= this.square.y + 20; ++y) {
                  label55:
                  for(int x = this.square.x - 20; x <= this.square.x + 20; ++x) {
                     IsoGridSquare square = IsoWorld.instance.CurrentCell.getGridSquare(x, y, z);
                     if (square != null) {
                        ArrayList<IsoMovingObject> objects = square.getMovingObjects();
                        Iterator var7 = objects.iterator();

                        while(true) {
                           IsoMovingObject obj;
                           do {
                              if (!var7.hasNext()) {
                                 continue label55;
                              }

                              obj = (IsoMovingObject)var7.next();
                           } while(!(obj instanceof IsoZombie) && !(obj instanceof IsoPlayer));

                           float dist = obj.DistToProper(this);
                           this.nearByCharacters.put(obj, dist);
                           this.processTarget(obj, (double)dist);
                        }
                     }
                  }
               }
            }

         }
      }
   }

   public void handleNpcHitReaction(HandWeapon var1, IsoGameCharacter attacker) {
      HashMap<String, Object> arguments = new HashMap();
      this.sendReactEvent(attacker, zombie.characters.IsoNpcPlayer.EventType.ATTACK, arguments);
      if (attacker instanceof IsoPlayer) {
         IsoPlayer attackingPlayer = (IsoPlayer)attacker;
         IsoPlayer var10001 = (IsoPlayer)attacker;
         int relationShipMod = 0;
         if (attackingPlayer.getGroup() == this.getGroup()) {
            if (var1.isRanged()) {
               this.Say("FriendlyFireRanged", true);
               if (this.getClosestAttackTarget() != null) {
                  relationShipMod = -3;
               } else {
                  relationShipMod = -40;
               }
            } else if ("Bare Hands".equals(var1.getName())) {
               this.Say("FriendlyFireShove", true);
               if (this.getClosestAttackTarget() != null) {
                  if (!GameClient.bClient && !GameServer.bServer) {
                     relationShipMod = -1;
                  }
               } else {
                  relationShipMod = -10;
               }
            } else {
               this.Say("FriendlyFireMelee", true);
               if (this.getClosestAttackTarget() != null) {
                  relationShipMod = -2;
               } else {
                  relationShipMod = -40;
               }
            }
         } else if (var1.isRanged()) {
            this.Say("HostileHitRanged", true);
            relationShipMod = -60;
         } else if ("Bare Hands".equals(var1.getName())) {
            this.Say("HostileHitShove", true);
            relationShipMod = -10;
         } else {
            this.Say("HostileHitMelee", true);
            relationShipMod = -60;
         }

         this.relationships.modifyRelationship(attackingPlayer, relationShipMod);
         int relationshipAfter = this.relationships.getRelationship(attackingPlayer);
         if (!attackingPlayer.isNPC() && relationshipAfter < 0 && this.getGroup() != null && this.getGroup().getLeader() != null) {
            IsoGameCharacter var9 = this.getGroup().getLeader().getInstance();
            if (var9 instanceof IsoPlayer) {
               IsoPlayer cmp = (IsoPlayer)var9;
               var10001 = (IsoPlayer)var9;
               if (attackingPlayer == cmp) {
                  this.getGroup().leaveGroup(this, "");
                  this.relationships.setRelationship(attackingPlayer, relationshipAfter);
               }
            }
         }
      }

   }

   public void sendReactEvent(IsoGameCharacter attacker, zombie.characters.IsoNpcPlayer.EventType type, HashMap<String, Object> arguments) {
      Iterator var5 = this.nearByCharacters.entrySet().iterator();

      while(var5.hasNext()) {
         Entry<IsoMovingObject, Float> character = (Entry)var5.next();
         Object var7 = character.getKey();
         if (var7 instanceof IsoNpcPlayer) {
            IsoNpcPlayer reactingNpc = (IsoNpcPlayer)var7;
            IsoNpcPlayer var10001 = (IsoNpcPlayer)var7;
            reactingNpc.reactToEvent(attacker, this, type, arguments);
         }
      }

   }

   public boolean reactToEvent(IsoGameCharacter performer, IsoPlayer victim, zombie.characters.IsoNpcPlayer.EventType type, HashMap<String, Object> arguments) {
      int year = GameTime.instance.getYear();
      int month = GameTime.instance.getMonth() + 1;
      int day = GameTime.instance.getDay() + 1;
      if (type != zombie.characters.IsoNpcPlayer.EventType.DEATH) {
         if (type != zombie.characters.IsoNpcPlayer.EventType.TRESPASSER && type != zombie.characters.IsoNpcPlayer.EventType.ATTACK && type != zombie.characters.IsoNpcPlayer.EventType.ZOMBIE && type != zombie.characters.IsoNpcPlayer.EventType.ROBBING && type != zombie.characters.IsoNpcPlayer.EventType.SCREAM && type != zombie.characters.IsoNpcPlayer.EventType.NOISE && type != zombie.characters.IsoNpcPlayer.EventType.LAUGH) {
            zombie.characters.IsoNpcPlayer.EventType var10000 = zombie.characters.IsoNpcPlayer.EventType.INSULT;
         }
      } else {
         if (this.relationships.getRelationship(victim) >= 75 || this.relationships.getRelationship(victim) >= 50 && this.relationships.getRelationshipType(victim) != RelationType.UNRELATED) {
            HashMap<String, String> args = new HashMap();
            args.put("<VICTIM>", victim.getForname());
            this.Say("ReactToDeathGeneral", true, args);
            if (this.getDescriptor().isAggressive()) {
               this.stats.setAnger(10.0F);
               if (performer instanceof IsoZombie) {
                  this.Say("ReactToDeathAngryZombie", true);
               } else if (performer instanceof IsoPlayer) {
                  this.Say("ReactToDeathAngryHuman", true);
               }
            } else {
               this.stats.setPanic(1.0F);
               this.Say("ReactToDeathCompassionate", true);
            }

            this.memories.addPostKnoxEventMemory(new DeathMemory(year, month, day, NpcMemoryFeeling.SAD, this, performer, victim));
            return true;
         }

         this.memories.addPostKnoxEventMemory(new DeathMemory(year, month, day, NpcMemoryFeeling.SAD, this, performer, victim));
      }

      return false;
   }

   public float Hit(HandWeapon var1, IsoGameCharacter var2, float var3, boolean var4, float var5, boolean var6) {
      this.handleNpcHitReaction(var1, var2);
      this.forcePlayerUpdate = true;
      return super.Hit(var1, var2, var3, var4, var5, var6);
   }

   public BuildingDef getSafeHouseBuildingDef() {
      BuildingDef buildingDef = null;
      if (this.getGroup() != null && this.isPlayerControlled() && GameServer.bServer) {
         SurvivorDesc leaderDesc = this.getGroup().leader;
         IsoPlayer player = (IsoPlayer)leaderDesc.getInstance();
         SafeHouse safeHouse = SafeHouse.hasSafehouse(player);
         if (safeHouse != null) {
            int tx = safeHouse.getX() + safeHouse.getW() / 2;
            int ty = safeHouse.getY() + safeHouse.getH() / 2;
            BuildingDef safeHouseDef = IsoWorld.instance.getMetaGrid().getBuildingAt(tx, ty);
            this.getGroup().Safehouse = safeHouseDef;
         } else {
            this.getGroup().Safehouse = null;
         }
      }

      buildingDef = this.getGroup().Safehouse;
      return buildingDef;
   }

   public IsoBuilding getSafeHouseBuilding() {
      BuildingDef buildingDef = this.getSafeHouseBuildingDef();
      if (buildingDef != null) {
         int centerX = buildingDef.getX() + buildingDef.getW() / 2;
         int centerY = buildingDef.getY() + buildingDef.getH() / 2;
         IsoGridSquare square = IsoWorld.instance.CurrentCell.getGridSquare(centerX, centerY, 0);
         if (square != null) {
            return square.getBuilding();
         }
      }

      return null;
   }

   public boolean claimSafeHouse(int x, int y) {
      BuildingDef npcSafeHouse = IsoWorld.instance.getMetaGrid().getBuildingAt(x, y);
      return NpcManager.claimNpcSafeHouse(this.getGroup(), npcSafeHouse);
   }

   public InventoryContainer getBackpack() {
      return this.cachedBackPack;
   }

   public void moveWeaponToBackpack(HandWeapon weapon) {
      if (!this.cachedBackPack.getInventory().contains(weapon) && weapon.getContainer() != null) {
         weapon.getContainer().DoRemoveItem(weapon);
         this.cachedBackPack.getInventory().AddItem(weapon);
      }

   }

   public boolean hasRoomInBackpack() {
      float currentWeight = this.cachedBackPack.getContentsWeight();
      float maxCapacity = (float)this.cachedBackPack.getEffectiveCapacity(this);
      return currentWeight <= maxCapacity * 0.8F;
   }

   public void save(ByteBuffer sliceBuffer, boolean unused) throws IOException {
      sliceBuffer.putFloat(this.getX());
      sliceBuffer.putFloat(this.getY());
      sliceBuffer.putFloat(this.getZ());
      sliceBuffer.putInt(this.dir.index());
      if (this.table != null && !this.table.isEmpty()) {
         sliceBuffer.put((byte)1);
         this.table.save(sliceBuffer);
      } else {
         sliceBuffer.put((byte)0);
      }

      if (this.descriptor == null) {
         sliceBuffer.put((byte)0);
      } else {
         sliceBuffer.put((byte)1);
         this.descriptor.save(sliceBuffer);
      }

      this.getVisual().save(sliceBuffer);
      ArrayList<InventoryItem> var3 = this.inventory.save(sliceBuffer, this);
      this.savedInventoryItems.clear();

      for(int i = 0; i < var3.size(); ++i) {
         this.savedInventoryItems.add((InventoryItem)var3.get(i));
      }

      sliceBuffer.put((byte)(this.Asleep ? 1 : 0));
      sliceBuffer.putFloat(this.ForceWakeUpTime);
      this.stats.save(sliceBuffer);
      this.BodyDamage.save(sliceBuffer);
      this.xp.save(sliceBuffer);
      if (this.leftHandItem != null) {
         sliceBuffer.putInt(this.inventory.getItems().indexOf(this.leftHandItem));
      } else {
         sliceBuffer.putInt(-1);
      }

      if (this.rightHandItem != null) {
         sliceBuffer.putInt(this.inventory.getItems().indexOf(this.rightHandItem));
      } else {
         sliceBuffer.putInt(-1);
      }

      sliceBuffer.put((byte)(this.OnFire ? 1 : 0));
      sliceBuffer.putFloat(this.DepressEffect);
      sliceBuffer.putFloat(this.DepressFirstTakeTime);
      sliceBuffer.putFloat(this.BetaEffect);
      sliceBuffer.putFloat(this.BetaDelta);
      sliceBuffer.putFloat(this.PainEffect);
      sliceBuffer.putFloat(this.PainDelta);
      sliceBuffer.putFloat(this.SleepingTabletEffect);
      sliceBuffer.putFloat(this.SleepingTabletDelta);
      sliceBuffer.putInt(0);
      sliceBuffer.putFloat(this.reduceInfectionPower);
      sliceBuffer.putInt(0);
      sliceBuffer.putInt(this.lastHourSleeped);
      sliceBuffer.putFloat(this.timeSinceLastSmoke);
      sliceBuffer.putFloat(this.beardGrowTiming);
      sliceBuffer.putFloat(this.hairGrowTiming);
      sliceBuffer.putDouble(this.getHoursSurvived());
      sliceBuffer.putInt(this.getZombieKills());
      if (this.wornItems.size() > 127) {
         throw new RuntimeException("too many worn items");
      } else {
         sliceBuffer.put((byte)this.wornItems.size());
         this.wornItems.forEach((wornItem) -> {
            GameWindow.WriteString(sliceBuffer, wornItem.getLocation());
            sliceBuffer.putShort((short)this.savedInventoryItems.indexOf(wornItem.getItem()));
         });
         sliceBuffer.putShort((short)this.savedInventoryItems.indexOf(this.getPrimaryHandItem()));
         sliceBuffer.putShort((short)this.savedInventoryItems.indexOf(this.getSecondaryHandItem()));
         sliceBuffer.putInt(this.getSurvivorKills());
         this.nutrition.save(sliceBuffer);
         sliceBuffer.put((byte)0);
         sliceBuffer.putInt(0);
         this.fitness.save(sliceBuffer);
         sliceBuffer.putShort((short)0);
         this.saveKnownMediaLines(sliceBuffer);
         sliceBuffer.putInt(this.relationships.getDefaultRelationship());
         sliceBuffer.putInt(0);
         HashMap<String, Integer> playerRelationships = this.relationships.getPlayerRelationships();
         sliceBuffer.putInt(playerRelationships.entrySet().size());
         Iterator var6 = this.relationships.getPlayerRelationships().entrySet().iterator();

         while(var6.hasNext()) {
            Entry<String, Integer> entry = (Entry)var6.next();
            GameWindow.WriteString(sliceBuffer, (String)entry.getKey());
            sliceBuffer.putInt((Integer)entry.getValue());
         }

         GameWindow.WriteString(sliceBuffer, this.getBehaviorTree().getName());
         GameWindow.WriteString(sliceBuffer, this.getGoal());
         GameWindow.WriteString(sliceBuffer, this.getSubGoal());
         this.tree.getGoalData().save(sliceBuffer);
         this.memories.save(sliceBuffer);
      }
   }

   public void load(ByteBuffer sliceBuffer) throws IOException {
      this.x = this.lx = this.nx = this.scriptnx = sliceBuffer.getFloat();
      this.y = this.ly = this.ny = this.scriptny = sliceBuffer.getFloat();
      this.z = this.lz = sliceBuffer.getFloat();
      this.dir = IsoDirections.fromIndex(sliceBuffer.getInt());
      if (sliceBuffer.get() == 1) {
         if (this.table == null) {
            this.table = LuaManager.platform.newTable();
         }

         this.table.load(sliceBuffer, 195);
      }

      if (sliceBuffer.get() == 1) {
         this.descriptor.load(sliceBuffer, 195, this);
      }

      this.setForname(this.getDescriptor().getForename());
      this.setSurname(this.getDescriptor().getSurname());
      String var10001 = this.getDescriptor().getForename();
      this.setDisplayName(var10001 + " " + this.getDescriptor().getSurname());
      var10001 = this.getDescriptor().getForename();
      this.setUsername(var10001 + " " + this.getDescriptor().getSurname());
      this.getVisual().load(sliceBuffer, 195);
      ArrayList<InventoryItem> loadedItems = this.inventory.load(sliceBuffer, 195);

      int gameCharLeftHandIndex;
      for(gameCharLeftHandIndex = 0; gameCharLeftHandIndex < loadedItems.size(); ++gameCharLeftHandIndex) {
         this.savedInventoryItems.add((InventoryItem)loadedItems.get(gameCharLeftHandIndex));
      }

      this.Asleep = sliceBuffer.get() == 1;
      this.ForceWakeUpTime = sliceBuffer.getFloat();
      this.stats.load(sliceBuffer, 195);
      this.BodyDamage.load(sliceBuffer, 195);
      this.xp.load(sliceBuffer, 195);
      gameCharLeftHandIndex = sliceBuffer.getInt();
      if (gameCharLeftHandIndex >= 0 && gameCharLeftHandIndex < this.inventory.IncludingObsoleteItems.size()) {
         this.leftHandItem = (InventoryItem)this.inventory.IncludingObsoleteItems.get(gameCharLeftHandIndex);
      }

      int gameCharRightHandIndex = sliceBuffer.getInt();
      if (gameCharRightHandIndex >= 0 && gameCharRightHandIndex < this.inventory.IncludingObsoleteItems.size()) {
         this.rightHandItem = (InventoryItem)this.inventory.IncludingObsoleteItems.get(gameCharRightHandIndex);
      }

      this.setEquipParent((InventoryItem)null, this.leftHandItem);
      this.setEquipParent((InventoryItem)null, this.rightHandItem);
      this.OnFire = sliceBuffer.get() == 1;
      this.DepressEffect = sliceBuffer.getFloat();
      this.DepressFirstTakeTime = sliceBuffer.getFloat();
      this.BetaEffect = sliceBuffer.getFloat();
      this.BetaDelta = sliceBuffer.getFloat();
      this.PainEffect = sliceBuffer.getFloat();
      this.PainDelta = sliceBuffer.getFloat();
      this.SleepingTabletEffect = sliceBuffer.getFloat();
      this.SleepingTabletDelta = sliceBuffer.getFloat();
      int nbrOfReadBooks = sliceBuffer.getInt();
      this.reduceInfectionPower = sliceBuffer.getFloat();
      int nbrOfKnownRecipes = sliceBuffer.getInt();
      this.lastHourSleeped = sliceBuffer.getInt();
      this.timeSinceLastSmoke = sliceBuffer.getFloat();
      this.beardGrowTiming = sliceBuffer.getFloat();
      this.hairGrowTiming = sliceBuffer.getFloat();
      this.setHoursSurvived(sliceBuffer.getDouble());
      this.setZombieKills(sliceBuffer.getInt());
      ArrayList<InventoryItem> savedInventoryItems = this.savedInventoryItems;
      byte nbrOfWornItems = sliceBuffer.get();

      for(byte i = 0; i < nbrOfWornItems; ++i) {
         String readString = GameWindow.ReadString(sliceBuffer);
         short wornItemIndex = sliceBuffer.getShort();
         if (wornItemIndex >= 0 && wornItemIndex < savedInventoryItems.size() && this.wornItems.getBodyLocationGroup().getLocation(readString) != null) {
            this.wornItems.setItem(readString, (InventoryItem)savedInventoryItems.get(wornItemIndex));
         }
      }

      short playerLeftHandIndex = sliceBuffer.getShort();
      if (playerLeftHandIndex >= 0 && playerLeftHandIndex < savedInventoryItems.size()) {
         this.leftHandItem = (InventoryItem)savedInventoryItems.get(playerLeftHandIndex);
         this.setSecondaryHandItem(this.leftHandItem);
      }

      short playerRightHandIndex = sliceBuffer.getShort();
      if (playerRightHandIndex >= 0 && playerRightHandIndex < savedInventoryItems.size()) {
         this.rightHandItem = (InventoryItem)savedInventoryItems.get(playerRightHandIndex);
         this.setPrimaryHandItem(this.rightHandItem);
         this.cachedWeapon = (HandWeapon)this.rightHandItem;
      }

      InventoryContainer backPack = (InventoryContainer)Type.tryCastTo(this.getClothingItem_Back(), InventoryContainer.class);
      this.cachedBackPack = backPack;
      this.setSurvivorKills(sliceBuffer.getInt());
      this.nutrition.load(sliceBuffer);
      sliceBuffer.get();
      int nbrOfMechanicsItems = sliceBuffer.getInt();
      this.fitness.load(sliceBuffer, 195);
      short nbrOfAlreadyReadBooks = sliceBuffer.getShort();
      this.loadKnownMediaLines(sliceBuffer, 195);
      this.relationships.setDefaultRelationship(sliceBuffer.getInt());
      sliceBuffer.getInt();
      int nbrOfPlayerRelationships = sliceBuffer.getInt();

      String goal;
      for(int i = 0; i < nbrOfPlayerRelationships; ++i) {
         goal = GameWindow.ReadString(sliceBuffer);
         int relationship = sliceBuffer.getInt();
         this.relationships.setPlayerRelationship(goal, relationship);
      }

      String treeStr = GameWindow.ReadString(sliceBuffer);
      if ("SurvivorBehaviorTree".equals(treeStr)) {
         this.tree = new SurvivorBehaviorTree(this);
      } else if ("BanditBehaviorTree".equals(treeStr)) {
         this.tree = new BanditBehaviorTree(this);
      } else if ("SoldierBehaviorTree".equals(treeStr)) {
         this.tree = new SoldierBehaviorTree(this);
      } else if ("PoliceBehaviorTree".equals(treeStr)) {
         this.tree = new PoliceBehaviorTree(this);
      } else {
         this.tree = new SurvivorBehaviorTree(this);
      }

      goal = GameWindow.ReadString(sliceBuffer);
      this.tree.setGoal(goal);
      String subGoal = GameWindow.ReadString(sliceBuffer);
      this.tree.setSubGoal(subGoal);
      KahluaTable goalState = LuaManager.platform.newTable();
      goalState.load(sliceBuffer, 195);
      this.tree.restoreGoalData(goalState);
      this.memories.load(this, sliceBuffer);
   }

   public float getCombatSpeed() {
      return this.combatSpeed;
   }

   public void setWornItem(String bodyPart, InventoryItem item, boolean boolSomething) {
      super.setWornItem(bodyPart, item, boolSomething);
      if (GameServer.bServer && !this.bIsInMeta) {
         NpcNetworking.sendSyncClothing(this, bodyPart, item);
      }

   }

   public void setPreferredWeapon(InventoryItem inventoryItem) {
      if (inventoryItem instanceof HandWeapon) {
         HandWeapon weapon = (HandWeapon)inventoryItem;
         HandWeapon var10001 = (HandWeapon)inventoryItem;
         this.cachedWeapon = weapon;
      }

   }

   public void setPrimaryHandItem(InventoryItem inventoryItem) {
      this.setEquipParent(this.leftHandItem, inventoryItem);
      this.leftHandItem = inventoryItem;
      if (GameServer.bServer) {
         NpcNetworking.sendUpdateHandEquips(this);
      }

      LuaEventManager.triggerEvent("OnNPCEquipPrimary", this, inventoryItem);
      this.resetEquippedHandsModels();
      this.setVariable("Weapon", WeaponType.getWeaponType(this).type);
      if (inventoryItem != null && inventoryItem instanceof HandWeapon && !StringUtils.isNullOrEmpty(((HandWeapon)inventoryItem).getFireMode())) {
         this.setVariable("FireMode", ((HandWeapon)inventoryItem).getFireMode());
      } else {
         this.clearVariable("FireMode");
      }

   }

   public void setSecondaryHandItem(InventoryItem inventoryItem) {
      this.setEquipParent(this.rightHandItem, inventoryItem);
      this.rightHandItem = inventoryItem;
      if (GameServer.bServer && !this.bIsInMeta) {
         NpcNetworking.sendUpdateHandEquips(this);
      }

      LuaEventManager.triggerEvent("OnNPCEquipSecondary", this, inventoryItem);
      this.resetEquippedHandsModels();
      this.setVariable("Weapon", WeaponType.getWeaponType(this).type);
   }

   public void Say(String message) {
      this.dialogue.Say(message, false);
   }

   public void Say(String message, boolean useTranslator) {
      this.dialogue.Say(message, useTranslator);
   }

   public void Say(String message, boolean useTranslator, HashMap<String, String> args) {
      this.dialogue.Say(message, useTranslator, args);
   }

   public void SayNoLimit(String message) {
      if (GameServer.bServer) {
         RangeBasedChat chatBase = (RangeBasedChat)ChatServer.chats.get(1);
         ChatMessage chatMessage = new ChatMessage(chatBase, message);
         chatMessage.setAuthor(this.getUsername());
         chatBase.sendMessageToChatMembers(chatMessage, this);
      } else {
         ChatManager.getInstance().showInfoMessage(this.getUsername(), message);
      }

   }

   public void Yell(String message) {
      this.dialogue.Yell(message, false);
   }

   public void Yell(String message, boolean useTranslator) {
      this.dialogue.Yell(message, useTranslator);
   }

   public void YellNoLimit(String message) {
      if (GameServer.bServer) {
         RangeBasedChat chatBase = (RangeBasedChat)ChatServer.chats.get(2);
         ChatMessage chatMessage = new ChatMessage(chatBase, message);
         chatMessage.setAuthor(this.getUsername());
         chatBase.sendMessageToChatMembers(chatMessage, this);
      } else {
         ChatManager.getInstance().sendMessageToChat(this.getUsername(), ChatType.shout, message);
      }

   }

   public boolean isPerformingAction(String string) {
      if (!this.CharacterActions.isEmpty()) {
         BaseAction action = (BaseAction)this.CharacterActions.get(0);
         if (action instanceof ISNpcBaseAction) {
            ISNpcBaseAction npcAction = (ISNpcBaseAction)action;
            return npcAction.npcActionName.equals(string);
         }
      }

      return false;
   }

   public void StartActionIfEmpty(BaseAction var1) {
      if (this.CharacterActions.isEmpty()) {
         this.CharacterActions.push(var1);
         if (var1.valid()) {
            var1.waitToStart();
         }
      }

   }

   public void QueueAction(BaseAction var1) {
      if (var1 instanceof ISNpcBaseAction) {
         ISNpcBaseAction newNpcAction = (ISNpcBaseAction)var1;
         ISNpcBaseAction var10001 = (ISNpcBaseAction)var1;
         Iterator var5 = this.CharacterActions.iterator();

         while(var5.hasNext()) {
            BaseAction action = (BaseAction)var5.next();
            if (action instanceof ISNpcBaseAction) {
               ISNpcBaseAction npcAction = (ISNpcBaseAction)action;
               var10001 = (ISNpcBaseAction)action;
               if (npcAction.npcActionName.equals(newNpcAction.npcActionName)) {
                  return;
               }
            }
         }
      }

      this.CharacterActions.add(var1);
   }

   public boolean isHealing() {
      boolean isHealing = this.isPerformingAction("ISApplyBandage");
      isHealing |= this.isPerformingAction("ISDisinfect");
      isHealing |= this.isPerformingAction("ISRemoveBullet");
      isHealing |= this.isPerformingAction("ISRemoveGlass");
      isHealing |= this.isPerformingAction("ISSplint");
      isHealing |= this.isPerformingAction("ISStitch");
      return isHealing;
   }

   public boolean actionWalkingIsAllowed() {
      if (!this.CharacterActions.isEmpty()) {
         BaseAction action = (BaseAction)this.CharacterActions.get(0);
         if (action instanceof ISNpcBaseAction) {
            ISNpcBaseAction npcAction = (ISNpcBaseAction)action;
            return !npcAction.getStopOnWalk();
         }
      }

      return true;
   }

   public boolean isActionQueued(String actionStr) {
      Iterator var3 = this.CharacterActions.iterator();

      while(var3.hasNext()) {
         BaseAction action = (BaseAction)var3.next();
         if (action instanceof ISNpcBaseAction) {
            ISNpcBaseAction npcAction = (ISNpcBaseAction)action;
            ISNpcBaseAction var10001 = (ISNpcBaseAction)action;
            if (npcAction.npcActionName.equals(actionStr)) {
               return true;
            }
         }
      }

      return false;
   }

   public float doBeatenVehicle(float n) {
      this.changeState(ForecastBeatenPlayerState.instance());
      float damageFromHitByACar = this.getDamageFromHitByACar(n);
      if (this.isAlive() && this.getCurrentState() != PlayerHitReactionState.instance() && this.getCurrentState() != PlayerFallDownState.instance() && this.getCurrentState() != PlayerOnGroundState.instance() && !this.isKnockedDown()) {
         if (damageFromHitByACar > 15.0F) {
            this.setKnockedDown(true);
            this.setReanimateTimer((float)(20 + Rand.Next(60)));
         }

         this.setHitReaction("HitReaction");
         this.actionContext.reportEvent("washit");
      }

      return damageFromHitByACar;
   }

   public float getDamageFromHitByACar(float n) {
      float n2 = 1.0F;
      switch(SandboxOptions.instance.DamageToPlayerFromHitByACar.getValue()) {
      case 1:
         n2 = 0.0F;
         break;
      case 2:
         n2 = 0.5F;
      case 3:
      default:
         break;
      case 4:
         n2 = 2.0F;
         break;
      case 5:
         n2 = 5.0F;
      }

      float n3 = n * n2;
      if (DebugOptions.instance.MultiplayerCriticalHit.getValue()) {
         n3 += 10.0F;
      }

      if (n3 > 0.0F) {
         int n4 = (int)(2.0F + n3 * 0.07F);

         for(int i = 0; i < n4; ++i) {
            int next = Rand.Next(BodyPartType.ToIndex(BodyPartType.Hand_L), BodyPartType.ToIndex(BodyPartType.MAX));
            BodyPart bodyPart = this.getBodyDamage().getBodyPart(BodyPartType.FromIndex(next));
            float max = Math.max(Rand.Next(n3 - 15.0F, n3), 5.0F);
            if (this.Traits.FastHealer.isSet()) {
               max *= 0.8F;
            } else if (this.Traits.SlowHealer.isSet()) {
               max *= 1.2F;
            }

            switch(SandboxOptions.instance.InjurySeverity.getValue()) {
            case 1:
               max *= 0.5F;
            case 2:
            default:
               break;
            case 3:
               max *= 1.5F;
            }

            float n5 = (float)((double)max * 0.9D);
            bodyPart.AddDamage(n5);
            if (n5 > 40.0F && Rand.Next(12) == 0) {
               bodyPart.generateDeepWound();
            }

            if (n5 > 10.0F && Rand.Next(100) <= 10 && SandboxOptions.instance.BoneFracture.getValue()) {
               bodyPart.setFractureTime(Rand.Next(Rand.Next(10.0F, n5 + 10.0F), Rand.Next(n5 + 20.0F, n5 + 30.0F)));
            }

            if (n5 > 30.0F && Rand.Next(100) <= 80 && SandboxOptions.instance.BoneFracture.getValue() && next == BodyPartType.ToIndex(BodyPartType.Head)) {
               bodyPart.setFractureTime(Rand.Next(Rand.Next(10.0F, n5 + 10.0F), Rand.Next(n5 + 20.0F, n5 + 30.0F)));
            }

            if (n5 > 10.0F && Rand.Next(100) <= 60 && SandboxOptions.instance.BoneFracture.getValue() && next > BodyPartType.ToIndex(BodyPartType.Groin)) {
               bodyPart.setFractureTime(Rand.Next(Rand.Next(10.0F, n5 + 20.0F), Rand.Next(n5 + 30.0F, n5 + 40.0F)));
            }
         }

         this.getBodyDamage().Update();
      }

      this.addBlood(n);
      this.updateMovementRates();
      if (GameServer.bServer && !this.bIsInMeta) {
         NpcNetworking.sendPlayerInjuries(this);
         NpcNetworking.sendPlayerDamage(this);
      }

      return n3;
   }

   protected void doDeferredMovement() {
      if (this.getHitReactionNetworkAI() != null) {
         if (this.getHitReactionNetworkAI().isStarted()) {
            this.getHitReactionNetworkAI().move();
            return;
         }

         if (this.isDead() && this.getHitReactionNetworkAI().isDoSkipMovement()) {
            return;
         }
      }

      AnimationPlayer animPlayer = this.getAnimationPlayer();
      if (animPlayer != null) {
         if (this.getPath2() != null && !this.isCurrentState(ClimbOverFenceState.instance()) && !this.isCurrentState(ClimbThroughWindowState.instance())) {
            if (this.isCurrentState(WalkTowardState.instance())) {
               DebugLog.General.warn("WalkTowardState but path2 != null");
               this.setPath2((Path)null);
            }
         } else {
            Vector2 vec = tempo;
            this.getDeferredMovement(vec);
            if (this.debugNpcEnable) {
               DebugLog.log("Moving upmodded with " + vec.x + "," + vec.y);
            }

            this.MoveUnmodded(vec);
         }
      }

   }

   public void hitConsequences(HandWeapon handWeapon, IsoGameCharacter isoGameCharacter, boolean b, float damage, boolean b2) {
      String variableString = isoGameCharacter.getVariableString("ZombieHitReaction");
      if ("Shot".equals(variableString)) {
         isoGameCharacter.setCriticalHit(Rand.Next(100) < ((IsoPlayer)isoGameCharacter).calculateCritChance(this));
      }

      if (isoGameCharacter instanceof IsoPlayer) {
         if (ServerOptions.getInstance().KnockedDownAllowed.getValue()) {
            this.setKnockedDown(isoGameCharacter.isCriticalHit());
         }
      } else {
         this.setKnockedDown(isoGameCharacter.isCriticalHit());
      }

      if (isoGameCharacter instanceof IsoPlayer) {
         if (!StringUtils.isNullOrEmpty(this.getHitReaction())) {
            this.actionContext.reportEvent("washitpvpagain");
         }

         this.actionContext.reportEvent("washitpvp");
         this.setVariable("hitpvp", true);
      } else {
         this.actionContext.reportEvent("washit");
      }

      if (!b) {
         this.BodyDamage.DamageFromWeapon(handWeapon);
         if ("Bite".equals(variableString)) {
            String testDotSide = this.testDotSide(isoGameCharacter);
            testDotSide.equals("FRONT");
            testDotSide.equals("BEHIND");
            if (testDotSide.equals("RIGHT")) {
               variableString = variableString + "LEFT";
            }

            if (testDotSide.equals("LEFT")) {
               variableString = variableString + "RIGHT";
            }

            if (variableString != null && !"".equals(variableString)) {
               this.setHitReaction(variableString);
            }
         } else if (!this.isKnockedDown()) {
            this.setHitReaction("HitReaction");
         }

      } else {
         isoGameCharacter.xp.AddXP(Perks.Strength, 2.0F);
         this.setHitForce(Math.min(0.5F, this.getHitForce()));
         this.setHitReaction("HitReaction");
         this.setHitFromBehind("BEHIND".equals(this.testDotSide(isoGameCharacter)));
      }
   }

   public boolean shouldDoInventory() {
      return true;
   }

   public void die() {
      if (!this.isOnDeathDone()) {
         this.becomeCorpse();
      }

   }

   public void becomeCorpse() {
      if (!this.isOnDeathDone()) {
         float random = (float)(Math.random() * 100.0D);
         HashMap<String, Object> arguments = new HashMap();
         this.sendReactEvent(this.getAttackedBy(), zombie.characters.IsoNpcPlayer.EventType.DEATH, arguments);
         this.Kill(this.getAttackedBy());
         this.setOnDeathDone(true);
         if (GameServer.bServer && !this.bIsInMeta) {
            NpcNetworking.sendPlayerDeath(this);
         }

         IsoDeadBody isoDeadBody = new IsoDeadBody(this);
         if (this.shouldBecomeZombieAfterDeath()) {
            isoDeadBody.reanimateLater();
         }

         if (GameServer.bServer && !this.bIsInMeta) {
            GameServer.sendBecomeCorpse(isoDeadBody);
            NpcNetworking.sendPlayerTimeout(this);
         }

      }
   }

   public boolean shouldBecomeCorpse() {
      return !this.getHitReactionNetworkAI().isSetup() && !this.getHitReactionNetworkAI().isStarted() ? this.isCurrentState(PlayerOnGroundState.instance()) : false;
   }

   public void OnDeath() {
      KnoxEventMainLoop.onCharacterDeath(this);
      super.OnDeath();
      this.StopAllActionQueue();
      this.dropHandItems();
   }

   public void update() {
      s_performance.update.invokeAndMeasure(this, IsoNpcPlayer::updateInternal1);
   }

   private void updateInternal1() {
      long startTime = System.nanoTime();
      if (this.tree != null) {
         long treeTime = System.nanoTime();
         long targetTime = System.nanoTime();
         String var10000;
         boolean updateInternal2;
         float var23;
         BooleanSandboxOption var24;
         if (this.bIsInMeta) {
            try {
               this.tree.evaluate();
               treeTime = System.nanoTime();
               this.updateMetaInternal();
            } catch (Exception var16) {
               var10000 = this.getUsername();
               DebugLog.log("Npc " + var10000 + " received exception " + var16.toString() + " while evaluating tree");
               if (this.exceptionThrottle == 0) {
                  this.Say("I received an error and have stopped working. Please ask me to do something else.");
                  var16.printStackTrace();
                  this.exceptionThrottle = 100;
               } else {
                  --this.exceptionThrottle;
               }
            }

            updateInternal2 = false;
            SandboxOption enableLongUpdateDebugOption = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.Debug_EnableNpcLongUpdatePrint");
            if (enableLongUpdateDebugOption instanceof BooleanSandboxOption) {
               BooleanSandboxOption bEnableLongUpdateDebugOption = (BooleanSandboxOption)enableLongUpdateDebugOption;
               var24 = (BooleanSandboxOption)enableLongUpdateDebugOption;
               updateInternal2 = bEnableLongUpdateDebugOption.getValue();
            }

            if (updateInternal2 && (treeTime - startTime) / 1000000L > 10L) {
               var10000 = this.getUsername();
               DebugLog.log(var10000 + ": total traversal " + (treeTime - startTime) / 1000000L + " ms");
            }

            if (this.debugNpcEnable) {
               var23 = this.getX();
               DebugLog.log("Finished update, npc pos: " + var23 + ", " + this.getY() + ", " + this.getZ());
            }

         } else {
            if (this.square != null) {
               if (this.bWasInMeta) {
                  this.checkAndAdjustToFreeSquare();
               }

               this.bWasInMeta = false;
            }

            try {
               this.findTargets();
               targetTime = System.nanoTime();
               if (this.lethalZombieTargets.size() > 3 && GameServer.bServer) {
                  IsoGameCharacter var8 = this.closestZombieAttackTarget;
                  if (var8 instanceof IsoZombie) {
                     IsoZombie zombie = (IsoZombie)var8;
                     IsoZombie var10001 = (IsoZombie)var8;
                     this.Yell("He's eating me!");
                     this.getBodyDamage().AddRandomDamageFromZombie(zombie, (String)null);
                  }
               }

               if (this.square != null) {
                  this.tree.evaluate();
               }
            } catch (Exception var18) {
               var10000 = this.getUsername();
               DebugLog.log("Npc " + var10000 + " received exception " + var18.toString() + " while evaluating tree");
               if (this.square != null) {
                  if (this.exceptionThrottle == 0) {
                     this.Say("I received an error and have stopped working. Please ask me to do something else.");
                     var18.printStackTrace();
                     this.exceptionThrottle = 100;
                  } else {
                     --this.exceptionThrottle;
                  }
               }
            }

            treeTime = System.nanoTime();

            try {
               updateInternal2 = this.updateInternal2();
               if (GameServer.bServer && (this.playerUpdateLimit.Check() || this.forcePlayerUpdate)) {
                  this.forcePlayerUpdate = false;
                  if (this.playerUpdateReliableLimit.Check()) {
                     NpcNetworking.sendPlayerUpdateReliable(this);
                  } else {
                     NpcNetworking.sendPlayerUpdate(this);
                  }
               }

               if (updateInternal2) {
                  this.updateLOS();
                  super.update();
               }

               if (this.debugNpcEnable) {
                  var23 = this.getX();
                  DebugLog.log("Finished update, npc pos: " + var23 + ", " + this.getY() + ", " + this.getZ());
               }

               long updaterTime = System.nanoTime();
               Iterator var11 = this.npcUpdaters.iterator();

               while(var11.hasNext()) {
                  zombie.characters.IsoNpcPlayer.NpcDamageUpdater updater = (zombie.characters.IsoNpcPlayer.NpcDamageUpdater)var11.next();
                  updater.update();
               }

               long endTime = System.nanoTime();
               boolean enableLongUpdateDebug = false;
               SandboxOption enableLongUpdateDebugOption = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.Debug_EnableNpcLongUpdatePrint");
               if (enableLongUpdateDebugOption instanceof BooleanSandboxOption) {
                  BooleanSandboxOption bEnableLongUpdateDebugOption = (BooleanSandboxOption)enableLongUpdateDebugOption;
                  var24 = (BooleanSandboxOption)enableLongUpdateDebugOption;
                  enableLongUpdateDebug = bEnableLongUpdateDebugOption.getValue();
               }

               if (enableLongUpdateDebug && (endTime - startTime) / 1000000L > 10L) {
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": targetting time " + (targetTime - startTime) / 1000000L + " ms");
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": tree traversal " + (treeTime - targetTime) / 1000000L + " ms");
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": object update " + (updaterTime - treeTime) / 1000000L + " ms");
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": updater " + (endTime - updaterTime) / 1000000L + " ms");
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": total " + (endTime - startTime) / 1000000L + " ms");
               }
            } catch (Exception var17) {
               var10000 = this.getUsername();
               DebugLog.log("Npc " + var10000 + " received exception " + var17.toString() + " while updating object");
               if (this.exceptionThrottle == 0) {
                  var17.printStackTrace();
                  this.exceptionThrottle = 100;
               } else {
                  --this.exceptionThrottle;
               }
            }

         }
      }
   }

   private void constructPath(Vector2i targetPoint) throws IllegalStateException {
      WaypointHandler waypointHandler = WaypointHandler.getInstance();
      int sx = Float.valueOf(this.getX()).intValue();
      int sy = Float.valueOf(this.getY()).intValue();
      Vector2i npcVector = new Vector2i(sx, sy);
      Waypoint firstPoint = waypointHandler.findClosestWaypoint(npcVector);
      Waypoint targetWaypoint = waypointHandler.findClosestWaypoint(targetPoint);
      this.pendingNpcControls.path = waypointHandler.getPath(firstPoint, targetWaypoint);
      Iterator<Waypoint> iter = this.pendingNpcControls.path.iterator();
      if (this.debugNpcEnable) {
         DebugLog.log("Constructed path:");

         while(iter.hasNext()) {
            Waypoint tmp = (Waypoint)iter.next();
            DebugLog.log(tmp.getId());
         }
      }

   }

   private float calculatePathLength(List<Waypoint> path, Vector2 startPoint, Vector2 targetPoint) {
      float totalDist = 0.0F;
      Vector2 currentPoint = new Vector2(startPoint);

      for(int i = 0; i < path.size(); ++i) {
         Waypoint nextWaypoint = (Waypoint)path.get(i);
         Vector2i nextPointI = nextWaypoint.getPos();
         Vector2 nextPoint = new Vector2();
         nextPoint.x = (float)nextPointI.x;
         nextPoint.y = (float)nextPointI.y;
         totalDist += currentPoint.distanceTo(nextPoint);
         currentPoint = new Vector2(nextPoint);
      }

      totalDist += currentPoint.distanceTo(targetPoint);
      return totalDist;
   }

   private void updateMetaInternal() {
      this.setPath2((Path)null);
      this.getPathFindBehavior2().cancel();
      float pathX = this.pendingNpcControls.pathX;
      float pathY = this.pendingNpcControls.pathY;
      List<Waypoint> path = this.pendingNpcControls.path;
      Waypoint currentWaypoint = this.pendingNpcControls.currentWaypoint;
      Vector2i oldTargetPoint = this.pendingNpcControls.targetPoint;
      Vector2 targetPointF = new Vector2(pathX, pathY);
      if (pathX > 0.0F && pathY > 0.0F) {
         float tdx = Math.abs(pathX - this.getX());
         float tdy = Math.abs(pathY - this.getY());
         if (tdx <= 0.1F && tdy <= 0.1F) {
            this.pendingNpcControls.path = null;
            this.pendingNpcControls.targetPoint = null;
            this.pendingNpcControls.currentWaypoint = null;
            return;
         }

         if (path == null || oldTargetPoint == null || oldTargetPoint.x != (int)pathX || oldTargetPoint.y != (int)pathY) {
            this.pendingNpcControls.targetPoint = new Vector2i((int)pathX, (int)pathY);

            try {
               this.constructPath(this.pendingNpcControls.targetPoint);
               path = this.pendingNpcControls.path;
            } catch (Exception var17) {
               return;
            }
         }

         Vector2 nextPos = null;
         if (currentWaypoint == null) {
            nextPos = new Vector2(pathX, pathY);
         } else {
            Vector2i nextPosI = currentWaypoint.getPos();
            nextPos = new Vector2((float)nextPosI.x, (float)nextPosI.y);
         }

         float pathDist;
         float secondDist;
         Vector2 startingPoint;
         if (path.size() == 1 && currentWaypoint == null) {
            startingPoint = new Vector2(this.getX(), this.getY());
            nextPos = new Vector2(nextPos);
            if (currentWaypoint == null && path.size() == 1) {
               currentWaypoint = (Waypoint)path.remove(0);
               nextPos.x = (float)currentWaypoint.getPos().x;
               nextPos.y = (float)currentWaypoint.getPos().x;
            }

            pathDist = startingPoint.distanceTo(nextPos) + nextPos.distanceTo(targetPointF);
            secondDist = startingPoint.distanceTo(targetPointF);
            if (secondDist < pathDist) {
               nextPos.x = pathX;
               nextPos.y = pathY;
            }
         }

         float closestDist;
         if (path.size() > 0) {
            if (currentWaypoint == null) {
               this.pendingNpcControls.currentWaypoint = currentWaypoint = (Waypoint)path.remove(0);
            }

            startingPoint = new Vector2(this.getX(), this.getY());
            ArrayList<Waypoint> tmpPath = new ArrayList(path);
            secondDist = this.calculatePathLength(tmpPath, startingPoint, targetPointF);
            tmpPath.add(0, currentWaypoint);
            closestDist = this.calculatePathLength(tmpPath, startingPoint, targetPointF);
            if (secondDist < closestDist && path.size() > 0) {
               this.pendingNpcControls.currentWaypoint = currentWaypoint = (Waypoint)path.remove(0);
               nextPos.x = (float)currentWaypoint.getPos().x;
               nextPos.y = (float)currentWaypoint.getPos().y;
            } else if (path.size() <= 2) {
               float dx = nextPos.x - this.getX();
               float dy = nextPos.y - this.getY();
               float directDist = (float)Math.sqrt((double)(dx * dx + dy * dy));
               if (directDist < closestDist) {
                  nextPos.x = pathX;
                  nextPos.y = pathY;
               }
            }
         }

         float dx = Float.valueOf(Math.abs(nextPos.x - this.getX()));
         pathDist = Float.valueOf(Math.abs(nextPos.y - this.getY()));
         secondDist = (float)Math.sqrt((double)(2.0F * this.pendingNpcControls.pathOffset * this.pendingNpcControls.pathOffset));
         closestDist = (float)Math.sqrt((double)(dx * dx + pathDist * pathDist));
         if (closestDist > secondDist) {
            nextPos.x -= this.getX();
            nextPos.y -= this.getY();
            nextPos.setLength(1.0F / (float)PerformanceSettings.getLockFPS());
            this.setLx(this.getLx() + nextPos.x);
            this.setLy(this.getLy() + nextPos.y);
            this.setX(this.getLx());
            this.setY(this.getLy());
         } else if (path.size() > 0) {
            this.pendingNpcControls.currentWaypoint = (Waypoint)path.remove(0);
         } else {
            currentWaypoint = null;
            this.pendingNpcControls.currentWaypoint = null;
         }
      }

      this.calculateStats();
      if (!this.CharacterActions.isEmpty()) {
         BaseAction var7 = (BaseAction)this.CharacterActions.get(0);
         boolean var9 = var7.valid();
         if (var9 && !var7.bStarted) {
            var7.waitToStart();
         } else if (var9 && !var7.finished() && !var7.forceComplete && !var7.forceStop) {
            var7.update();
         }

         if (!var9 || var7.finished() || var7.forceComplete || var7.forceStop) {
            if (var7.finished() || var7.forceComplete) {
               var7.perform();
               var9 = true;
            }

            if (var7.finished() && !var7.loopAction || var7.forceComplete || var7.forceStop || !var9) {
               if (var7.bStarted && (var7.forceStop || !var9)) {
                  var7.stop();
               }

               this.CharacterActions.removeElement(var7);
            }
         }
      }

   }

   private boolean updateInternal2() {
      if (GameServer.bServer) {
         ServerLOS.instance.doServerZombieLOS(this);
         ServerLOS.instance.updateLOS(this);
      }

      if (!this.attackStarted) {
         this.setInitiateAttack(false);
         this.setAttackType((String)null);
      }

      if ((this.isRunning() || this.isSprinting()) && this.getDeferredMovement(IsoPlayer.tempo).getLengthSquared() > 0.0F) {
         this.runningTime += GameTime.getInstance().getMultiplier() / 1.6F;
      } else {
         this.runningTime = 0.0F;
      }

      if (this.getLastCollideTime() > 0.0F) {
         this.setLastCollideTime(this.getLastCollideTime() - GameTime.getInstance().getMultiplier() / 1.6F);
      }

      this.updateDeathDragDown();
      this.networkAI.update();
      this.doDeferredMovement();
      this.updateHitByVehicle();
      this.vehicle4testCollision = null;
      if (!GameServer.bServer) {
         this.updateEmitter();
      }

      this.updateTemperatureCheck();
      this.updateAimingStance();
      if (SystemDisabler.doCharacterStats) {
         this.nutrition.update();
      }

      this.fitness.update();
      SafetySystemManager.update(this);
      if (this.bDeathFinished) {
         return false;
      } else {
         if (this.getCurrentBuildingDef() != null && !this.isInvisible()) {
            this.getCurrentBuildingDef().setHasBeenVisited(true);
         }

         if (this.checkSafehouse > 0 && GameServer.bServer) {
            --this.checkSafehouse;
            if (this.checkSafehouse == 0) {
               this.checkSafehouse = 200;
               SafeHouse safeHouse = SafeHouse.isSafeHouse(this.getCurrentSquare(), (String)null, false);
               if (safeHouse != null) {
                  safeHouse.updateSafehouse(this);
                  if (GameServer.bServer && !ServerOptions.instance.SafehouseAllowTrepass.getValue() && this.getVehicle() == null && safeHouse != null) {
                     IsoPlayer groupPlayer = null;
                     if (this.isPlayerControlled()) {
                        groupPlayer = this.getGroup().leader.getInstance() instanceof IsoPlayer ? (IsoPlayer)this.getGroup().leader.getInstance() : null;
                     }

                     if (groupPlayer == null || !safeHouse.isOwner(groupPlayer)) {
                        this.setX(this.x - 1.0F);
                        this.setY(this.y - 1.0F);
                        this.setLx(this.x - 1.0F);
                        this.setLy(this.y - 1.0F);
                     }
                  }
               }
            }
         }

         this.TimeSinceOpenDoor += GameTime.instance.getMultiplier();
         this.lastTargeted += GameTime.instance.getMultiplier();
         this.targetedByZombie = false;
         this.checkActionGroup();
         if (this.closestZombie > 1.2F) {
            this.slowTimer = -1.0F;
            this.slowFactor = 0.0F;
         }

         this.ContextPanic -= 1.5F * GameTime.instance.getTimeDelta();
         if (this.ContextPanic < 0.0F) {
            this.ContextPanic = 0.0F;
         }

         this.lastSeenZombieTime += (double)(GameTime.instance.getGameWorldSecondsSinceLastUpdate() / 60.0F / 60.0F);
         LuaEventManager.triggerEvent("OnNPCUpdate", this);
         if (this.pressedMovement(false)) {
            this.ContextPanic = 0.0F;
            this.ticksSincePressedMovement = 0.0F;
         } else {
            this.ticksSincePressedMovement += GameTime.getInstance().getMultiplier() / 1.6F;
         }

         this.setVariable("pressedMovement", this.pressedMovement(true));
         this.updateEquippedBaggageContainer();
         this.updateSneakKey();
         this.checkIsNearWall();
         this.updateExt();
         this.updateInteractKeyPanic();
         if (this.isAsleep()) {
            this.m_isPlayerMoving = false;
         }

         if (!this.getIgnoreMovement() && !this.isAsleep()) {
            if (this.checkActionsBlockingMovement()) {
               if (this.getVehicle() != null && this.getVehicle().getDriver() == this && this.getVehicle().getController() != null) {
                  this.getVehicle().getController().clientControls.reset();
                  this.getVehicle().updatePhysics();
               }

               return true;
            } else {
               this.enterExitVehicle();
               this.checkActionGroup();
               this.checkWalkTo();
               if (this.checkActionsBlockingMovement()) {
                  return true;
               } else if (this.getVehicle() != null) {
                  this.updateWhileInVehicle();
                  if (this.isDead()) {
                     this.getVehicle().exit(this);
                  }

                  return true;
               } else {
                  this.checkVehicleContainers();
                  this.setCollidable(true);
                  this.bSeenThisFrame = false;
                  this.bCouldBeSeenThisFrame = false;
                  if (this.updateUseKey()) {
                     return true;
                  } else {
                     boolean isAttacking = false;
                     boolean meleePressed = false;
                     this.setRunning(false);
                     this.setSprinting(false);
                     this.useChargeTime = this.chargeTime;
                     if (!this.isBlockMovement()) {
                        if (!this.isCharging && !this.isChargingLT) {
                           this.chargeTime = 0.0F;
                        } else {
                           this.chargeTime += 1.0F * GameTime.instance.getMultiplier();
                        }

                        this.UpdateInputState(this.inputState);
                        meleePressed = this.inputState.bMelee;
                        isAttacking = this.inputState.isAttacking;
                        this.setRunning(this.inputState.bRunning);
                        this.setSprinting(this.inputState.bSprinting);
                        if (this.isSprinting() && !this.isJustMoved()) {
                           this.setSprinting(false);
                        }

                        if (this.isSprinting()) {
                           this.setRunning(false);
                        }

                        if (this.inputState.bSprinting && !this.isSprinting()) {
                           this.setRunning(true);
                        }

                        this.setIsAiming(this.inputState.isAiming);
                        this.isCharging = this.inputState.isCharging;
                        this.isChargingLT = this.inputState.isChargingLT;
                        this.updateMovementRates();
                        if (this.isAiming()) {
                           this.StopAllActionQueueAiming();
                        }

                        if (isAttacking) {
                           this.setIsAiming(true);
                        }

                        this.Waiting = false;
                        if (this.isAiming()) {
                           this.setMoving(false);
                           this.setRunning(false);
                           this.setSprinting(false);
                        }

                        ++this.TicksSinceSeenZombie;
                     }

                     if ((double)this.playerMoveDir.x == 0.0D && (double)this.playerMoveDir.y == 0.0D) {
                        this.setForceRun(false);
                        this.setForceSprint(false);
                     }

                     this.movementLastFrame.x = this.playerMoveDir.x;
                     this.movementLastFrame.y = this.playerMoveDir.y;
                     if (this.stateMachine.getCurrent() != StaggerBackState.instance() && this.stateMachine.getCurrent() != FakeDeadZombieState.instance()) {
                        this.setJustMoved(false);
                        MoveVars s_moveVars = this.currentMoveVars;
                        this.updateMovementFromInput(s_moveVars);
                        if (!this.JustMoved && this.hasPath() && !this.getPathFindBehavior2().bStopping) {
                           this.JustMoved = true;
                        }

                        float deltaX = s_moveVars.strafeX;
                        float deltaY = s_moveVars.strafeY;
                        if (this.stats.endurance < this.stats.endurancedanger && Rand.Next((int)(300.0F * GameTime.instance.getInvMultiplier())) == 0) {
                           this.xp.AddXP(Perks.Fitness, 1.0F);
                        }

                        this.setBeenMovingSprinting();
                        float n = 1.0F;
                        float n2 = 0.0F;
                        if (this.isJustMoved()) {
                           if (!this.isRunning() && !this.isSprinting()) {
                              n2 = 1.0F;
                           } else {
                              n2 = 1.5F;
                           }
                        }

                        float n3 = 1.0F * n2;
                        if (n3 > 1.0F) {
                           n3 *= this.getSprintMod();
                        }

                        if (n3 > 1.0F && this.Traits.Athletic.isSet()) {
                           n3 *= 1.2F;
                        }

                        if (n3 > 1.0F) {
                           if (this.Traits.Overweight.isSet()) {
                              n3 *= 0.99F;
                           }

                           if (this.Traits.Obese.isSet()) {
                              n3 *= 0.85F;
                           }

                           if (this.getNutrition().getWeight() > 120.0D) {
                              n3 *= 0.97F;
                           }

                           if (this.Traits.OutOfShape.isSet()) {
                              n3 *= 0.99F;
                           }

                           if (this.Traits.Unfit.isSet()) {
                              n3 *= 0.8F;
                           }
                        }

                        this.updateEndurance(n3);
                        if (this.isAiming() && this.isJustMoved()) {
                           n3 *= 0.7F;
                        }

                        if (this.isAiming()) {
                           n3 *= this.getNimbleMod();
                        }

                        this.isWalking = false;
                        if (n3 > 0.0F) {
                           this.isWalking = true;
                           LuaEventManager.triggerEvent("OnNPCMove", this);
                        }

                        if (this.isJustMoved()) {
                           this.sprite.Animate = true;
                        }

                        if (this.m_meleePressed = meleePressed) {
                           if (!this.m_lastAttackWasShove) {
                              this.setMeleeDelay(Math.min(this.getMeleeDelay(), 2.0F));
                           }

                           if (!this.bBannedAttacking && this.isAuthorizeShoveStomp() && this.CanAttack() && this.getMeleeDelay() <= 0.0F) {
                              this.setDoShove(true);
                              if (!this.isCharging && !this.isChargingLT) {
                                 this.setIsAiming(false);
                              }

                              this.AttemptAttack(this.useChargeTime);
                              this.useChargeTime = 0.0F;
                              this.chargeTime = 0.0F;
                           }
                        } else if (this.isAiming() && this.CanAttack()) {
                           if (this.DragCharacter != null) {
                              this.DragObject = null;
                              this.DragCharacter.Dragging = false;
                              this.DragCharacter = null;
                           }

                           if (isAttacking && !this.bBannedAttacking) {
                              this.sprite.Animate = true;
                              if (this.getRecoilDelay() <= 0.0F && this.getMeleeDelay() <= 0.0F) {
                                 this.AttemptAttack(this.useChargeTime);
                              }

                              this.useChargeTime = 0.0F;
                              this.chargeTime = 0.0F;
                           }
                        }

                        if (this.isAiming()) {
                           Vector2 set = IsoPlayer.tempVector2.set(this.pendingNpcControls.aimDirX, this.pendingNpcControls.aimDirY);
                           this.DirectionFromVector(set);
                           this.setForwardDirection(set);
                           s_moveVars.NewFacing = this.dir;
                        }

                        if (this.getForwardDirection().x == 0.0F && this.getForwardDirection().y == 0.0F) {
                           this.setForwardDirection(this.dir.ToVector());
                        }

                        if (this.lastAngle.x != this.getForwardDirection().x || this.lastAngle.y != this.getForwardDirection().y) {
                           this.lastAngle.x = this.getForwardDirection().x;
                           this.lastAngle.y = this.getForwardDirection().y;
                           this.dirtyRecalcGridStackTime = 2.0F;
                        }

                        this.stats.endurance = PZMath.clamp(this.stats.endurance, 0.0F, 1.0F);
                        AnimationPlayer animationPlayer = this.getAnimationPlayer();
                        if (animationPlayer != null && animationPlayer.isReady()) {
                           this.dir = IsoDirections.fromAngle(IsoPlayer.tempVector2.setLengthAndDirection(animationPlayer.getAngle() + animationPlayer.getTwistAngle(), 1.0F));
                        } else if (!this.bFalling && !this.isAiming() && !isAttacking) {
                           this.dir = s_moveVars.NewFacing;
                        }

                        this.playerMoveDir.x = s_moveVars.moveX;
                        this.playerMoveDir.y = s_moveVars.moveY;
                        if (!this.isAiming() && this.isJustMoved()) {
                           this.playerMoveDir.x = this.getForwardDirection().x;
                           this.playerMoveDir.y = this.getForwardDirection().y;
                        }

                        if (this.isJustMoved()) {
                           if (this.isSprinting()) {
                              this.CurrentSpeed = 1.5F;
                           } else if (this.isRunning()) {
                              this.CurrentSpeed = 1.0F;
                           } else {
                              this.CurrentSpeed = 0.5F;
                           }
                        } else {
                           this.CurrentSpeed = 0.0F;
                        }

                        boolean isInMeleeAttack = this.IsInMeleeAttack();
                        if (!this.CharacterActions.isEmpty() && ((BaseAction)this.CharacterActions.get(0)).overrideAnimation) {
                           isInMeleeAttack = true;
                        }

                        if (!isInMeleeAttack && !this.isForceOverrideAnim()) {
                           if (this.getPath2() == null) {
                              if (this.CurrentSpeed > 0.0F && (!this.bClimbing || this.lastFallSpeed > 0.0F)) {
                                 if (!this.isRunning() && !this.isSprinting()) {
                                    this.StopAllActionQueueWalking();
                                 } else {
                                    this.StopAllActionQueueRunning();
                                 }
                              }
                           } else {
                              this.StopAllActionQueueWalking();
                           }
                        }

                        if (this.slowTimer > 0.0F) {
                           this.slowTimer -= GameTime.instance.getRealworldSecondsSinceLastUpdate();
                           this.CurrentSpeed *= 1.0F - this.slowFactor;
                           this.slowFactor -= GameTime.instance.getMultiplier() / 100.0F;
                           if (this.slowFactor < 0.0F) {
                              this.slowFactor = 0.0F;
                           }
                        } else {
                           this.slowFactor = 0.0F;
                        }

                        this.playerMoveDir.setLength(this.CurrentSpeed);
                        if (this.playerMoveDir.x != 0.0F || this.playerMoveDir.y != 0.0F) {
                           this.dirtyRecalcGridStackTime = 10.0F;
                        }

                        if (this.getPath2() != null && this.current != this.last) {
                           this.dirtyRecalcGridStackTime = 10.0F;
                        }

                        this.closestZombie = 1000000.0F;
                        this.weight = 0.3F;
                        this.separate();
                        this.updateSleepingPillsTaken();
                        this.updateTorchStrength();
                        this.m_isPlayerMoving = this.isJustMoved() || this.getPath2() != null && !this.getPathFindBehavior2().bStopping;
                        boolean inTrees = this.isInTrees();
                        if (inTrees) {
                           float n4 = "parkranger".equals(this.getDescriptor().getProfession()) ? 1.3F : 1.0F;
                           float n5 = "lumberjack".equals(this.getDescriptor().getProfession()) ? 1.15F : n4;
                           if (this.isRunning()) {
                              n5 *= 1.1F;
                           }

                           this.setVariable("WalkSpeedTrees", n5);
                        }

                        if ((inTrees || this.m_walkSpeed < 0.4F || this.m_walkInjury > 0.5F) && this.isSprinting() && !this.isGhostMode()) {
                           if ((double)this.runSpeedModifier < 1.0D) {
                              this.setMoodleCantSprint(true);
                           }

                           this.setSprinting(false);
                           this.setRunning(true);
                           if (this.isInTreesNoBush()) {
                              this.setForceSprint(false);
                              this.setBumpType("left");
                              this.setVariable("BumpDone", false);
                              this.setVariable("BumpFall", true);
                              this.setVariable("TripObstacleType", "tree");
                              this.actionContext.reportEvent("wasBumped");
                           }
                        }

                        this.m_deltaX = deltaX;
                        this.m_deltaY = deltaY;
                        this.m_windspeed = ClimateManager.getInstance().getWindSpeedMovement();
                        this.m_windForce = ClimateManager.getInstance().getWindForceMovement(this, this.getForwardDirection().getDirectionNeg());
                        return true;
                     } else {
                        return true;
                     }
                  }
               }
            }
         } else {
            return true;
         }
      }
   }

   public void postupdate() {
      s_performance.postUpdate.invokeAndMeasure(this, IsoNpcPlayer::postupdateInternal);
   }

   private void postupdateInternal() {
      GameTime instance = GameTime.getInstance();
      float n = 1.0F / instance.getMinutesPerDay() / 60.0F * instance.getMultiplier() / 2.0F;
      this.setHoursSurvived(this.getHoursSurvived() + (double)n);
      this.getBodyDamage().setBodyPartsLastState();
      if (!this.bIsInMeta) {
         boolean hasHitReaction = this.hasHitReaction();
         super.postupdate();
         if (hasHitReaction && this.hasHitReaction() && !this.isCurrentState(PlayerHitReactionState.instance()) && !this.isCurrentState(PlayerHitReactionPVPState.instance())) {
            this.setHitReaction("");
         }

         if (GameServer.bServer && !this.bIsInMeta && this.itemSendFrequency.Check()) {
            Entry entry;
            Iterator var5;
            if (!this.itemsToAdd.isEmpty()) {
               var5 = this.itemsToAdd.entrySet().iterator();

               while(var5.hasNext()) {
                  entry = (Entry)var5.next();
                  if (((ItemContainer)entry.getKey()).getParent() != null) {
                     NpcNetworking.sendAddInventoryItemToContainer(this, (ItemContainer)entry.getKey(), (ArrayList)entry.getValue());
                  }
               }
            }

            this.itemsToAdd.clear();
            if (!this.itemsToRemove.isEmpty()) {
               var5 = this.itemsToRemove.entrySet().iterator();

               while(var5.hasNext()) {
                  entry = (Entry)var5.next();
                  if (((ItemContainer)entry.getKey()).getParent() != null) {
                     NpcNetworking.sendRemoveInventoryItemFromContainer(this, (ItemContainer)entry.getKey(), (ArrayList)entry.getValue());
                  }
               }
            }

            this.itemsToRemove.clear();
         }

      }
   }

   public void pressedAttack(boolean b) {
      boolean sprinting = this.isSprinting();
      this.setSprinting(false);
      this.setForceSprint(false);
      if (!this.attackStarted && !this.isCurrentState(PlayerHitReactionState.instance())) {
         if (!this.isCurrentState(PlayerHitReactionPVPState.instance())) {
            if (this.primaryHandModel != null && !StringUtils.isNullOrEmpty(this.primaryHandModel.maskVariableValue) && this.secondaryHandModel != null && !StringUtils.isNullOrEmpty(this.secondaryHandModel.maskVariableValue)) {
               this.setDoShove(false);
               this.setForceShove(false);
               this.setInitiateAttack(false);
               this.attackStarted = false;
               this.setAttackType((String)null);
            } else if (this.getPrimaryHandItem() != null && this.getPrimaryHandItem().getItemReplacementPrimaryHand() != null && this.getSecondaryHandItem() != null && this.getSecondaryHandItem().getItemReplacementSecondHand() != null) {
               this.setDoShove(false);
               this.setForceShove(false);
               this.setInitiateAttack(false);
               this.attackStarted = false;
               this.setAttackType((String)null);
            } else {
               if (!this.attackStarted) {
                  this.setVariable("StartedAttackWhileSprinting", sprinting);
               }

               this.setInitiateAttack(true);
               this.attackStarted = true;
               this.setCriticalHit(false);
               this.setAttackFromBehind(false);
               WeaponType weaponType = WeaponType.getWeaponType(this);
               this.setAttackType((String)PZArrayUtil.pickRandom(weaponType.possibleAttack));
               this.combatSpeed = this.calculateCombatSpeed();
               if (b) {
                  SwipeStatePlayer.instance().CalcAttackVars(this, this.attackVars);
               }

               String variableString = this.getVariableString("Weapon");
               if (variableString != null && variableString.equals("throwing") && !this.attackVars.bDoShove) {
                  this.setAttackAnimThrowTimer(2000L);
                  this.setIsAiming(true);
               }

               this.attackVars.bDoShove = this.isDoShove();
               this.attackVars.bAimAtFloor = this.isAimAtFloor();
               if (this.attackVars.bDoShove && !this.isAuthorizeShoveStomp()) {
                  this.setDoShove(false);
                  this.setForceShove(false);
                  this.setInitiateAttack(false);
                  this.attackStarted = false;
                  this.setAttackType((String)null);
               } else {
                  this.useHandWeapon = this.attackVars.getWeapon(this);
                  this.setAimAtFloor(this.attackVars.bAimAtFloor);
                  this.setDoShove(this.attackVars.bDoShove);
                  this.targetOnGround = (IsoGameCharacter)this.attackVars.targetOnGround.getMovingObject();
                  if (this.attackVars.getWeapon(this) != null && !StringUtils.isNullOrEmpty(this.attackVars.getWeapon(this).getFireMode())) {
                     this.setVariable("FireMode", this.attackVars.getWeapon(this).getFireMode());
                  } else {
                     this.clearVariable("FireMode");
                  }

                  if (this.useHandWeapon != null && weaponType.isRanged && !this.bDoShove) {
                     this.setRecoilDelay((float)this.useHandWeapon.getRecoilDelay() * (1.0F - (float)this.getPerkLevel(Perks.Aiming) / 30.0F));
                  }

                  int next = Rand.Next(0, 3);
                  if (next == 0) {
                     this.setVariable("AttackVariationX", Rand.Next(-1.0F, -0.5F));
                  }

                  if (next == 1) {
                     this.setVariable("AttackVariationX", 0.0F);
                  }

                  if (next == 2) {
                     this.setVariable("AttackVariationX", Rand.Next(0.5F, 1.0F));
                  }

                  this.setVariable("AttackVariationY", 0.0F);
                  if (b) {
                     SwipeStatePlayer.instance().CalcHitList(this, true, this.attackVars, this.hitList);
                  }

                  IsoGameCharacter isoGameCharacter = null;
                  if (!this.hitList.isEmpty()) {
                     isoGameCharacter = (IsoGameCharacter)Type.tryCastTo(((HitInfo)this.hitList.get(0)).getObject(), IsoGameCharacter.class);
                  }

                  if (isoGameCharacter == null) {
                     if (this.isAiming() && !this.m_meleePressed && this.useHandWeapon != this.bareHands) {
                        this.setDoShove(false);
                        this.setForceShove(false);
                     }

                     this.m_lastAttackWasShove = this.bDoShove;
                     if (weaponType.canMiss && !this.isAimAtFloor()) {
                        this.setAttackType("miss");
                     }

                     if (this.isAiming() && this.bDoShove) {
                        this.setVariable("bShoveAiming", true);
                     } else {
                        this.clearVariable("bShoveAiming");
                     }

                  } else {
                     this.setAttackFromBehind(this.isBehind(isoGameCharacter));
                     float distanceTo = IsoUtils.DistanceTo(isoGameCharacter.x, isoGameCharacter.y, this.x, this.y);
                     this.setVariable("TargetDist", distanceTo);
                     int calculateCritChance = this.calculateCritChance(isoGameCharacter);
                     if (isoGameCharacter instanceof IsoZombie) {
                        IsoZombie isoZombie = (IsoZombie)isoGameCharacter;
                        IsoZombie var10001 = (IsoZombie)isoGameCharacter;
                        IsoZombie closestZombieToOtherZombie = this.getClosestZombieToOtherZombie(isoZombie);
                        if (!this.attackVars.bAimAtFloor && (double)distanceTo > 1.25D && weaponType == WeaponType.spear && (closestZombieToOtherZombie == null || (double)IsoUtils.DistanceTo(isoGameCharacter.x, isoGameCharacter.y, closestZombieToOtherZombie.x, closestZombieToOtherZombie.y) > 1.7D)) {
                           this.setAttackType("overhead");
                           calculateCritChance += 30;
                        }
                     }

                     if (!isoGameCharacter.isOnFloor()) {
                        isoGameCharacter.setHitFromBehind(this.isAttackFromBehind());
                     }

                     if (this.isAttackFromBehind()) {
                        if (isoGameCharacter instanceof IsoZombie && ((IsoZombie)isoGameCharacter).target == null) {
                           calculateCritChance += 30;
                        } else {
                           calculateCritChance += 5;
                        }
                     }

                     if (isoGameCharacter instanceof IsoPlayer && weaponType.isRanged && !this.bDoShove) {
                        calculateCritChance = (int)(this.attackVars.getWeapon(this).getStopPower() * (1.0F + (float)this.getPerkLevel(Perks.Aiming) / 15.0F));
                     }

                     this.setCriticalHit(Rand.Next(100) < calculateCritChance);
                     if (DebugOptions.instance.MultiplayerCriticalHit.getValue()) {
                        this.setCriticalHit(true);
                     }

                     if (this.isAttackFromBehind() && this.attackVars.bCloseKill && isoGameCharacter instanceof IsoZombie && ((IsoZombie)isoGameCharacter).target == null) {
                        this.setCriticalHit(true);
                     }

                     if (this.isCriticalHit() && !this.attackVars.bCloseKill && !this.bDoShove && weaponType == WeaponType.knife) {
                        this.setCriticalHit(false);
                     }

                     this.setAttackWasSuperAttack(false);
                     if (this.stats.NumChasingZombies > 1 && this.attackVars.bCloseKill && !this.bDoShove && weaponType == WeaponType.knife) {
                        this.setCriticalHit(false);
                     }

                     if (this.isCriticalHit()) {
                        this.combatSpeed *= 1.1F;
                     }

                     if (Core.bDebug) {
                        DebugLog.Combat.debugln("Hit zombie dist: " + distanceTo + " crit: " + this.isCriticalHit() + " (" + calculateCritChance + "%) from behind: " + this.isAttackFromBehind());
                     }

                     if (this.isAiming() && this.bDoShove) {
                        this.setVariable("bShoveAiming", true);
                     } else {
                        this.clearVariable("bShoveAiming");
                     }

                     if (this.useHandWeapon != null && weaponType.isRanged) {
                        this.setRecoilDelay((float)(this.useHandWeapon.getRecoilDelay() - this.getPerkLevel(Perks.Aiming) * 2));
                     }

                     this.m_lastAttackWasShove = this.bDoShove;
                  }
               }
            }
         }
      }
   }

   public boolean AttemptAttack(float var1) {
      HandWeapon var2 = null;
      if (this.leftHandItem instanceof HandWeapon) {
         var2 = (HandWeapon)this.leftHandItem;
      } else {
         var2 = this.bareHands;
      }

      if (var2 != this.bareHands && this instanceof IsoPlayer) {
         AttackVars var3 = new AttackVars();
         SwipeStatePlayer.instance().CalcAttackVars(this, var3);
         this.setDoShove(var3.bDoShove);
         if (LuaHookManager.TriggerHook("NPCAttack", this, var1, var2)) {
            return false;
         }
      }

      return this.DoAttack(var1);
   }

   protected void updateMovementFromInput(MoveVars moveVars) {
      moveVars.moveX = 0.0F;
      moveVars.moveY = 0.0F;
      moveVars.strafeX = 0.0F;
      moveVars.strafeY = 0.0F;
      moveVars.NewFacing = this.dir;
      if (!this.isBlockMovement()) {
         if (!(this.fallTime > 2.0F)) {
            moveVars.moveX = this.pendingNpcControls.moveX;
            moveVars.moveY = this.pendingNpcControls.moveY;
            float offset = this.pendingNpcControls.pathOffset;
            boolean bStopping = false;
            float pathY;
            IsoDoor passedDoor;
            IsoObject var7;
            boolean checkBlocked;
            IsoDoor var10001;
            IsoGridSquare current;
            IsoGridSquare next;
            if (moveVars.moveX == 0.0F && moveVars.moveY == 0.0F) {
               if (this.pendingNpcControls.pathObject != null || this.pendingNpcControls.pathX > 0.0F && this.pendingNpcControls.pathY > 0.0F) {
                  this.wasMovingManually = false;
                  float pathX = this.pendingNpcControls.pathX;
                  pathY = this.pendingNpcControls.pathY;
                  float pathZ = this.pendingNpcControls.pathZ;
                  boolean checkInside = this.pendingNpcControls.bCheckInside;
                  checkBlocked = this.pendingNpcControls.bCheckBlocked;
                  IsoGridSquare square;
                  IsoGridSquare targetSquare;
                  if (this.pendingNpcControls.pathX > 0.0F && this.pendingNpcControls.pathY > 0.0F) {
                     pathX = this.pendingNpcControls.pathX;
                     pathY = this.pendingNpcControls.pathY;
                     pathZ = this.pendingNpcControls.pathZ;
                  } else if (this.pendingNpcControls.pathObject != null) {
                     IsoObject targetObject = this.pendingNpcControls.pathObject;
                     IsoGridSquare square = targetObject.getSquare();
                     IsoGridSquare closestSquare = null;
                     double closestSquareDist = Double.MAX_VALUE;
                     IsoGridSquare var67;
                     if (square != null) {
                        IsoGridSquare var15 = square.nav[IsoDirections.N.index()];
                        if (var15 instanceof IsoGridSquare) {
                           IsoGridSquare tmpSquare = (IsoGridSquare)var15;
                           var67 = (IsoGridSquare)var15;
                           if (tmpSquare.isFree(true)) {
                              closestSquare = tmpSquare;
                              closestSquareDist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                           }
                        }
                     }

                     if (square != null) {
                        IsoGridSquare var17 = square.nav[IsoDirections.S.index()];
                        if (var17 instanceof IsoGridSquare) {
                           IsoGridSquare tmpSquare = (IsoGridSquare)var17;
                           var67 = (IsoGridSquare)var17;
                           if (tmpSquare.isFree(true)) {
                              double dist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                              if (dist < closestSquareDist) {
                                 closestSquare = tmpSquare;
                                 closestSquareDist = dist;
                              }
                           }
                        }
                     }

                     if (square != null) {
                        IsoGridSquare var19 = square.nav[IsoDirections.W.index()];
                        if (var19 instanceof IsoGridSquare) {
                           targetSquare = (IsoGridSquare)var19;
                           var67 = (IsoGridSquare)var19;
                           if (targetSquare.isFree(true)) {
                              double dist = (double)targetSquare.DistToProper(this.getCurrentSquare());
                              if (dist < closestSquareDist) {
                                 closestSquare = targetSquare;
                                 closestSquareDist = dist;
                              }
                           }
                        }
                     }

                     if (square != null) {
                        IsoGridSquare var21 = square.nav[IsoDirections.E.index()];
                        if (var21 instanceof IsoGridSquare) {
                           IsoGridSquare tmpSquare = (IsoGridSquare)var21;
                           var67 = (IsoGridSquare)var21;
                           if (tmpSquare.isFree(true)) {
                              double dist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                              if (dist < closestSquareDist) {
                                 closestSquare = tmpSquare;
                                 closestSquareDist = dist;
                              }
                           }
                        }
                     }

                     if (closestSquare == null) {
                        if (square != null) {
                           IsoGridSquare var23 = square.nav[IsoDirections.NW.index()];
                           if (var23 instanceof IsoGridSquare) {
                              IsoGridSquare tmpSquare = (IsoGridSquare)var23;
                              var67 = (IsoGridSquare)var23;
                              if (tmpSquare.isFree(true)) {
                                 closestSquareDist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                              }
                           }
                        }

                        if (square != null) {
                           square = square.nav[IsoDirections.NE.index()];
                           if (square instanceof IsoGridSquare) {
                              IsoGridSquare tmpSquare = (IsoGridSquare)square;
                              var67 = (IsoGridSquare)square;
                              if (tmpSquare.isFree(true)) {
                                 double dist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                                 if (dist < closestSquareDist) {
                                    closestSquareDist = dist;
                                 }
                              }
                           }
                        }

                        if (square != null) {
                           IsoGridSquare var27 = square.nav[IsoDirections.SW.index()];
                           if (var27 instanceof IsoGridSquare) {
                              IsoGridSquare tmpSquare = (IsoGridSquare)var27;
                              var67 = (IsoGridSquare)var27;
                              if (tmpSquare.isFree(true)) {
                                 double dist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                                 if (dist < closestSquareDist) {
                                    closestSquareDist = dist;
                                 }
                              }
                           }
                        }

                        if (square != null) {
                           IsoGridSquare var29 = square.nav[IsoDirections.SE.index()];
                           if (var29 instanceof IsoGridSquare) {
                              IsoGridSquare tmpSquare = (IsoGridSquare)var29;
                              var67 = (IsoGridSquare)var29;
                              if (tmpSquare.isFree(true)) {
                                 double dist = (double)tmpSquare.DistToProper(this.getCurrentSquare());
                                 if (dist < closestSquareDist) {
                                    ;
                                 }
                              }
                           }
                        }
                     }

                     pathX = this.pendingNpcControls.pathObject.getX() + 0.5F;
                     pathY = this.pendingNpcControls.pathObject.getY() + 0.5F;
                     pathZ = this.pendingNpcControls.pathObject.getZ();
                  } else {
                     bStopping = true;
                  }

                  if (this.debugNpcEnable) {
                     DebugLog.log("pathX: " + pathX);
                     DebugLog.log("pathY: " + pathY);
                     DebugLog.log("pathZ: " + pathZ);
                     DebugLog.log("offset: " + offset);
                  }

                  float tx;
                  float ty;
                  if (offset == 0.0F) {
                     tx = Math.abs(this.getPathFindBehavior2().getTargetX() - pathX);
                     ty = Math.abs(this.getPathFindBehavior2().getTargetY() - pathY);
                     if (tx > 0.1F || ty > 0.1F || this.pendingNpcControls.lastResult == BehaviorResult.Failed) {
                        if (this.debugNpcEnable) {
                           DebugLog.log("Resetting pathfinding to location, offset == 0");
                        }

                        this.getPathFindBehavior2().cancel();
                        this.setPath2((Path)null);
                        if (pathX > 0.0F && pathY > 0.0F) {
                           this.pathToLocationF(pathX, pathY, pathZ);
                        }
                     }
                  } else {
                     this.wasMovingManually = false;
                     tx = this.getPathFindBehavior2().getTargetX();
                     ty = this.getPathFindBehavior2().getTargetY();
                     float tz = this.getPathFindBehavior2().getTargetZ();
                     if (tx > pathX + offset + 0.1F || tx < pathX - offset - 0.1F || ty > pathY + offset + 0.1F || ty < pathY - offset - 0.1F || (int)tz != (int)pathZ || this.pendingNpcControls.lastResult == BehaviorResult.Failed) {
                        if (this.debugNpcEnable) {
                           DebugLog.log("Min x: " + (pathX - offset));
                           DebugLog.log("Max x: " + (pathX + offset));
                           DebugLog.log("Min y: " + (pathY - offset));
                           DebugLog.log("Max y: " + (pathY + offset));
                           DebugLog.log("tx: " + tx);
                           DebugLog.log("ty: " + ty);
                           DebugLog.log("tz: " + tz);
                           DebugLog.log("pathX: " + pathX);
                           DebugLog.log("pathY: " + pathY);
                           DebugLog.log("pathZ: " + pathZ);
                        }

                        int txI = Float.valueOf(pathX).intValue();
                        int tyI = Float.valueOf(pathY).intValue();
                        int offsetI = Float.valueOf(offset).intValue();
                        float closestX = 0.0F;
                        float closestY = 0.0F;
                        float closestDist = Float.MAX_VALUE;

                        for(targetSquare = IsoWorld.instance.CurrentCell.getGridSquare(txI, tyI, Float.valueOf(pathZ).intValue()); (closestX == 0.0F || closestY == 0.0F) && offsetI < 10 && targetSquare != null; ++offsetI) {
                           for(int y = tyI - offsetI; y <= tyI + offsetI; ++y) {
                              for(int x = txI - offsetI; x <= txI + offsetI; ++x) {
                                 float tmpX = (float)x + 0.5F;
                                 float tmpY = (float)y + 0.5F;
                                 float tmpDist = tmpX + tmpY;
                                 if (this.debugNpcEnable) {
                                    tmpDist = tmpX + tmpY;
                                 }

                                 ArrayList<IsoObject> wallCheck = KnoxEventMathAPI.bresenHamLineAlgo(x, y, txI, tyI);
                                 if (wallCheck == null || wallCheck.size() <= 0) {
                                    square = IsoWorld.instance.CurrentCell.getGridSquare(x, y, (int)pathZ);
                                    if (square != null && square.isFree(true) && (!checkInside || square.isInARoom() == targetSquare.isInARoom()) && (!checkBlocked || !square.isBlockedTo(targetSquare)) && tmpDist < closestDist) {
                                       closestX = tmpX;
                                       closestY = tmpY;
                                       closestDist = tmpDist;
                                    }
                                 }
                              }
                           }
                        }

                        if (this.debugNpcEnable) {
                           DebugLog.log("Resetting pathfinding to location, offset > 0");
                           DebugLog.log("Target: " + closestX + "," + closestY);
                        }

                        this.getPathFindBehavior2().cancel();
                        this.setPath2((Path)null);
                        if (closestX > 0.0F && closestY > 0.0F) {
                           this.pathToLocationF(closestX, closestY, pathZ);
                        } else if (this.invalidDestinationThrottle == 0) {
                           DebugLog.log(this.getUsername() + ": My pathfinding destination variables are messed up.");
                           DebugLog.log(this.getUsername() + ": I wanted to go to " + pathX + "," + pathY);
                           this.invalidDestinationThrottle = 100;
                        } else {
                           --this.invalidDestinationThrottle;
                        }
                     }
                  }

                  if (!bStopping) {
                     if (this.getPathTargetX() > 0 && this.getPathTargetY() > 0) {
                        this.pendingNpcControls.lastResult = this.getPathFindBehavior2().update();
                        if (this.debugNpcEnable) {
                           DebugLog.log("Pathfinding got result: " + this.pendingNpcControls.lastResult.name());
                           DebugLog.log("Path: " + String.valueOf(this.getPath2()));
                           DebugLog.log("Path current length: " + this.getPathFindBehavior2().getPathLength());
                           DebugLog.log("Finder progress: " + String.valueOf(this.getFinder().progress));
                        }

                        if (this.pendingNpcControls.lastResult == BehaviorResult.Succeeded || this.pendingNpcControls.lastResult == BehaviorResult.Failed) {
                           BehaviorResult var10000 = this.pendingNpcControls.lastResult;
                           var10000 = BehaviorResult.Failed;
                           this.getPathFindBehavior2().cancel();
                           this.setPath2((Path)null);
                        }
                     } else if (this.invalidDestinationThrottle == 0) {
                        DebugLog.log(this.getUsername() + ": My pathfinding destination variables are messed up.");
                        DebugLog.log(this.getUsername() + ": I wanted to go to " + pathX + "," + pathY);
                        this.invalidDestinationThrottle = 100;
                     } else {
                        --this.invalidDestinationThrottle;
                     }
                  } else {
                     this.wasMovingManually = false;
                     this.getPathFindBehavior2().cancel();
                     this.setPath2((Path)null);
                  }
               } else {
                  this.getPathFindBehavior2().cancel();
                  this.setPath2((Path)null);
               }
            } else {
               this.getPathFindBehavior2().cancel();
               this.setPath2((Path)null);
               if (this.stateMachine.getCurrent() == PathFindState.instance()) {
                  this.setDefaultState();
               }

               if (moveVars.moveX != 0.0F || moveVars.moveY != 0.0F) {
                  if (this.pendingNpcControls.bAiming) {
                     IsoPlayer.tempo.set(this.pendingNpcControls.aimDirX, this.pendingNpcControls.aimDirY);
                     IsoPlayer.tempo.normalize();
                     moveVars.NewFacing = IsoDirections.fromAngle(IsoPlayer.tempo);
                     Vector2 aimVec = new Vector2(this.pendingNpcControls.aimDirX, this.pendingNpcControls.aimDirY);
                     IsoPlayer.tempo.set(moveVars.moveX, moveVars.moveY);
                     IsoPlayer.tempo.normalize();
                     pathY = aimVec.angleBetween(IsoPlayer.tempo);
                     moveVars.moveX = 0.0F;
                     if (pathY < 0.7853982F && pathY > -0.7853982F) {
                        moveVars.moveY = 1.0F;
                     } else {
                        moveVars.moveY = -1.0F;
                     }

                     IsoPlayer.tempo.set(moveVars.moveX, moveVars.moveY);
                     this.setJustMoved(true);
                     this.setMoveDelta(1.0F);
                     if (this.isStrafing()) {
                        moveVars.strafeX = IsoPlayer.tempo.x;
                        moveVars.strafeY = IsoPlayer.tempo.y;
                        this.m_IPX = moveVars.moveX;
                        this.m_IPY = moveVars.moveY;
                     } else {
                        IsoPlayer.tempo.set(moveVars.moveX, -moveVars.moveY);
                        IsoPlayer.tempo.normalize();
                        IsoPlayer.tempo.rotate(-0.7853982F);
                        this.setForwardDirection(IsoPlayer.tempo);
                     }
                  } else {
                     IsoPlayer.tempo.set(moveVars.moveX, moveVars.moveY);
                     this.setJustMoved(true);
                     this.setMoveDelta(1.0F);
                     this.setForwardDirection(IsoPlayer.tempo);
                  }

                  current = this.getCurrentSquare();
                  next = IsoWorld.instance.CurrentCell.getGridSquare((double)(this.getX() + this.pendingNpcControls.moveX), (double)(this.getY() + this.pendingNpcControls.moveY), (double)this.getZ());
                  if (current != null && next != null) {
                     var7 = next.getDoorTo(current);
                     if (var7 instanceof IsoDoor) {
                        passedDoor = (IsoDoor)var7;
                        var10001 = (IsoDoor)var7;
                        if (!passedDoor.IsOpen() && !passedDoor.isLocked()) {
                           passedDoor.ToggleDoor(this);
                        }
                     }
                  }
               }

               this.pendingNpcControls.bAiming = false;
               if (!this.wasMovingManually && GameServer.bServer && !this.bIsInMeta) {
                  NpcNetworking.sendEvent(this, "Update");
               }

               this.wasMovingManually = true;
               if (this.debugNpcEnable) {
                  DebugLog.log("moveVars moveX: " + moveVars.moveX);
                  DebugLog.log("moveVars moveY: " + moveVars.moveY);
                  DebugLog.log("NewFacing: " + String.valueOf(moveVars.NewFacing));
                  DebugLog.log("pending aimX: " + this.pendingNpcControls.aimDirX);
                  DebugLog.log("pending aimY: " + this.pendingNpcControls.aimDirY);
               }
            }

            current = this.getCurrentSquare();
            next = this.getLastSquare();
            if (current != null && next != null) {
               var7 = next.getDoorTo(current);
               if (var7 instanceof IsoDoor) {
                  passedDoor = (IsoDoor)var7;
                  var10001 = (IsoDoor)var7;
                  if (!passedDoor.IsOpen()) {
                  }
               }
            }

            boolean var66;
            label353: {
               if (this.square != null) {
                  BuildingDef var40 = NpcManager.getNpcSafeHouse(this);
                  if (var40 instanceof BuildingDef) {
                     BuildingDef buildingDef = (BuildingDef)var40;
                     BuildingDef var68 = (BuildingDef)var40;
                     if ((float)buildingDef.getX() >= this.getX() && (float)buildingDef.getX2() <= this.getX() && (float)buildingDef.getY() >= this.getY() && (float)buildingDef.getY2() <= this.getY()) {
                        var66 = true;
                        break label353;
                     }
                  }
               }

               var66 = false;
            }

            checkBlocked = var66;
            if (this.current != null && this.current.nav[IsoDirections.N.index()] != null) {
               IsoObject var50 = current.getDoorTo(this.current.nav[IsoDirections.N.index()]);
               if (var50 instanceof IsoDoor) {
                  IsoDoor door = (IsoDoor)var50;
                  var10001 = (IsoDoor)var50;
                  if (checkBlocked) {
                     if (GameServer.bServer) {
                        this.getMapKnowledge().setKnownBlockedDoor(door, false);
                     }

                     door.setLockedByKey(false);
                     door.setLocked(false);
                     door.setIsLocked(false);
                  } else if (GameServer.bServer) {
                     this.getMapKnowledge().setKnownBlockedDoor(door, door.isLocked() && !this.square.isOutside());
                  }
               }
            }

            if (this.current != null && this.current.nav[IsoDirections.S.index()] != null) {
               IsoObject var45 = current.getDoorTo(this.current.nav[IsoDirections.S.index()]);
               if (var45 instanceof IsoDoor) {
                  IsoDoor door = (IsoDoor)var45;
                  var10001 = (IsoDoor)var45;
                  if (checkBlocked) {
                     if (GameServer.bServer) {
                        this.getMapKnowledge().setKnownBlockedDoor(door, false);
                     }

                     door.setLockedByKey(false);
                     door.setLocked(false);
                     door.setIsLocked(false);
                  } else if (GameServer.bServer) {
                     this.getMapKnowledge().setKnownBlockedDoor(door, door.isLocked() && !this.square.isOutside());
                  }
               }
            }

            if (this.current != null && this.current.nav[IsoDirections.W.index()] != null) {
               IsoObject var51 = current.getDoorTo(this.current.nav[IsoDirections.W.index()]);
               if (var51 instanceof IsoDoor) {
                  IsoDoor door = (IsoDoor)var51;
                  var10001 = (IsoDoor)var51;
                  if (checkBlocked) {
                     if (GameServer.bServer) {
                        this.getMapKnowledge().setKnownBlockedDoor(door, false);
                     }

                     door.setLockedByKey(false);
                     door.setLocked(false);
                     door.setIsLocked(false);
                  } else if (GameServer.bServer) {
                     this.getMapKnowledge().setKnownBlockedDoor(door, door.isLocked() && !this.square.isOutside());
                  }
               }
            }

            if (this.current != null && this.current.nav[IsoDirections.E.index()] != null) {
               IsoObject var55 = current.getDoorTo(this.current.nav[IsoDirections.E.index()]);
               if (var55 instanceof IsoDoor) {
                  IsoDoor door = (IsoDoor)var55;
                  var10001 = (IsoDoor)var55;
                  if (checkBlocked) {
                     if (GameServer.bServer) {
                        this.getMapKnowledge().setKnownBlockedDoor(door, false);
                     }

                     door.setLockedByKey(false);
                     door.setLocked(false);
                     door.setIsLocked(false);
                  } else if (GameServer.bServer) {
                     this.getMapKnowledge().setKnownBlockedDoor(door, door.isLocked() && !this.square.isOutside());
                  }
               }
            }

            if (this.current != null) {
               this.current.isOutside();
            }

            this.pendingNpcControls.moveX = 0.0F;
            this.pendingNpcControls.moveY = 0.0F;
            this.pendingNpcControls.pathX = 0.0F;
            this.pendingNpcControls.pathY = 0.0F;
            this.pendingNpcControls.pathZ = 0.0F;
            this.pendingNpcControls.pathOffset = -1.0F;
            this.pendingNpcControls.pathObject = null;
            if (this.isJustMoved()) {
               this.getForwardDirection().normalize();
            }

         }
      }
   }

   protected void updateAimingStance() {
      if (this.isVariable("LeftHandMask", "RaiseHand")) {
         this.clearVariable("LeftHandMask");
      }

      if (this.isAiming() && !this.isCurrentState(SwipeStatePlayer.instance())) {
         HandWeapon handWeapon = (HandWeapon)Type.tryCastTo(this.getPrimaryHandItem(), HandWeapon.class);
         HandWeapon handWeapon2 = handWeapon == null ? this.bareHands : handWeapon;
         SwipeStatePlayer.instance().calcValidTargets(this, handWeapon2, true, IsoPlayer.s_targetsProne, IsoPlayer.s_targetsStanding);
         HitInfo hitInfo = IsoPlayer.s_targetsStanding.isEmpty() ? null : (HitInfo)IsoPlayer.s_targetsStanding.get(0);
         HitInfo hitInfo2 = IsoPlayer.s_targetsProne.isEmpty() ? null : (HitInfo)IsoPlayer.s_targetsProne.get(0);
         if (SwipeStatePlayer.instance().isProneTargetBetter(this, hitInfo, hitInfo2)) {
            hitInfo = null;
         }

         boolean b = this.isAttackAnim() || this.getVariableBoolean("ShoveAnim") || this.getVariableBoolean("StompAnim");
         if (!b) {
            this.setAimAtFloor(false);
         }

         if (hitInfo != null) {
            if (!b) {
               this.setAimAtFloor(false);
            }
         } else if (hitInfo2 != null && !b) {
            this.setAimAtFloor(true);
         }

         if (hitInfo != null && !this.isAttackAnim() && handWeapon2.getSwingAnim() != null && handWeapon2.CloseKillMove != null && hitInfo.distSq < handWeapon2.getMinRange() * handWeapon2.getMinRange() && (this.getSecondaryHandItem() == null || this.getSecondaryHandItem().getItemReplacementSecondHand() == null)) {
            this.setVariable("LeftHandMask", "RaiseHand");
         }

         SwipeStatePlayer.instance().hitInfoPool.release(IsoPlayer.s_targetsStanding);
         SwipeStatePlayer.instance().hitInfoPool.release(IsoPlayer.s_targetsProne);
         IsoPlayer.s_targetsStanding.clear();
         IsoPlayer.s_targetsProne.clear();
      }
   }

   public boolean isAiming() {
      return this.isAiming;
   }

   public void faceThisObject(IsoObject object) {
      if (this.pendingNpcControls.bAiming) {
         float dx = object.getX() - this.getX();
         float dy = object.getY() - this.getY();
         Vector2 vec = new Vector2(dx, dy);
         vec.normalize();
         this.pendingNpcControls.aimDirX = vec.getX();
         this.pendingNpcControls.aimDirY = vec.getY();
      } else {
         super.faceThisObject(object);
      }

   }

   public void faceLocation(float x, float y) {
      if (this.pendingNpcControls.bAiming) {
         float dx = x - this.getX();
         float dy = y - this.getY();
         Vector2 vec = new Vector2(dx, dy);
         vec.normalize();
         this.pendingNpcControls.aimDirX = vec.getX();
         this.pendingNpcControls.aimDirY = vec.getY();
      } else {
         super.faceLocation(x, y);
      }

   }

   public boolean pressedMovement(boolean b) {
      this.setVariable("pressedRunButton", this.pendingNpcControls.bRunning);
      if (GameServer.bServer) {
         if (!b && (this.isBlockMovement() || this.isIgnoreInputsForDirection())) {
            this.networkAI.setPressedMovement(false);
            this.networkAI.usePathFind = false;
            return false;
         }

         if (this.pendingNpcControls.moveX != 0.0F && this.pendingNpcControls.moveY != 0.0F) {
            this.networkAI.setPressedMovement(true);
            this.networkAI.usePathFind = false;
            return true;
         }

         if (this.pendingNpcControls.pathObject != null || this.pendingNpcControls.pathX != 0.0F && this.pendingNpcControls.pathY != 0.0F && this.pendingNpcControls.pathZ != 0.0F) {
            this.networkAI.usePathFind = true;
         }

         this.networkAI.setPressedMovement(false);
         this.networkAI.usePathFind = false;
      }

      return false;
   }

   protected void UpdateInputState(InputState inputState) {
      inputState.bMelee = false;
      inputState.isAttacking = this.isCharging && this.pendingNpcControls.bAttacking;
      if (this.pendingNpcControls.bMelee && this.authorizeMeleeAction) {
         inputState.bMelee = true;
         inputState.isAttacking = false;
      }

      if (this.pendingNpcControls.bAiming) {
         this.TimeRightPressed += GameTime.getInstance().getRealworldSecondsSinceLastUpdate();
      } else {
         this.TimeRightPressed = 0.0F;
      }

      inputState.isAiming = this.pendingNpcControls.bAiming && this.TimeRightPressed >= 0.15F && StringUtils.isNullOrEmpty(this.getVariableString("BumpFallType"));
      if (!this.isCharging) {
         inputState.isCharging = this.pendingNpcControls.bAiming && this.TimeRightPressed >= 0.15F;
      } else {
         inputState.isCharging = this.pendingNpcControls.bAiming;
      }

      if (this.isAllowRun()) {
         inputState.bRunning = this.pendingNpcControls.bRunning;
      }

      if (inputState.bRunning || inputState.bSprinting) {
         this.setForceAim(false);
      }

      if (this.isForceAim()) {
         inputState.isAiming = true;
         inputState.isCharging = true;
      }

      if (this.isForceRun()) {
         inputState.bRunning = true;
      }

      if (this.isForceSprint()) {
         inputState.bSprinting = true;
      }

      if (this.debugNpcEnable) {
         DebugLog.log("Current input state:");
         DebugLog.log("isAiming = " + inputState.isAiming);
         DebugLog.log("isCharging = " + inputState.isCharging);
         DebugLog.log("isAttacking = " + inputState.isAttacking);
         DebugLog.log("bMelee= " + inputState.bMelee);
         DebugLog.log("bRunning = " + inputState.bRunning);
         DebugLog.log("bSprinting = " + inputState.bSprinting);
      }

      this.pendingNpcControls.bCharging = false;
      this.pendingNpcControls.bAttacking = false;
      this.pendingNpcControls.bMelee = false;
      this.pendingNpcControls.bRunning = false;
      this.pendingNpcControls.bSprinting = false;
   }

   protected void updateSneakKey() {
      if (!this.isBlockMovement() && this.pendingNpcControls.bSneaking != this.isSneaking()) {
         if (!this.bSneakDebounce) {
            this.setSneaking(this.pendingNpcControls.bSneaking);
            this.bSneakDebounce = true;
         }
      } else {
         this.bSneakDebounce = false;
      }

   }

   protected void calculateStats() {
      if (!LuaHookManager.TriggerHook("CalculateStats", this)) {
         this.stats.endurance = PZMath.clamp(this.stats.endurance, 0.0F, 1.0F);
         this.stats.endurancelast = this.stats.endurance;
         if (this.isUnlimitedEndurance()) {
            this.stats.endurance = 1.0F;
         }

         Stats stats = this.stats;
         if (this.stats.Tripping) {
            stats = this.stats;
            stats.TrippingRotAngle += 0.06F;
         }

         float tmpF = 1.0F;
         if (this.Traits.HighThirst.isSet()) {
            tmpF = (float)((double)tmpF * 2.0D);
         }

         if (this.Traits.LowThirst.isSet()) {
            tmpF = (float)((double)tmpF * 0.5D);
         }

         if (this.Asleep) {
            stats.thirst = (float)((double)stats.thirst + ZomboidGlobals.ThirstSleepingIncrease * SandboxOptions.instance.getStatsDecreaseMultiplier() * (double)GameTime.instance.getMultiplier() * (double)GameTime.instance.getDeltaMinutesPerDay() * (double)tmpF);
         } else {
            stats.thirst = (float)((double)stats.thirst + ZomboidGlobals.ThirstIncrease * SandboxOptions.instance.getStatsDecreaseMultiplier() * (double)GameTime.instance.getMultiplier() * (this.IsRunning() ? 1.2D : 1.0D) * (double)GameTime.instance.getDeltaMinutesPerDay() * (double)tmpF * this.getThirstMultiplier());
         }

         if (this.stats.thirst > 1.0F) {
            this.stats.thirst = 1.0F;
         }

         tmpF = 1.0F;
         if (this.Traits.Cowardly.isSet()) {
            tmpF = 2.0F;
         }

         if (this.Traits.Brave.isSet()) {
            tmpF = 0.3F;
         }

         if (this.stats.Panic > 100.0F) {
            this.stats.Panic = 100.0F;
         }

         if (this.BodyDamage.getNumPartsBitten() > 0) {
            stats.stress = (float)((double)stats.stress + ZomboidGlobals.StressFromBiteOrScratch * (double)GameTime.instance.getMultiplier() * (double)GameTime.instance.getDeltaMinutesPerDay());
         }

         if (this.BodyDamage.getNumPartsScratched() > 0) {
            stats.stress = (float)((double)stats.stress + ZomboidGlobals.StressFromBiteOrScratch * (double)GameTime.instance.getMultiplier() * (double)GameTime.instance.getDeltaMinutesPerDay());
         }

         if (this.BodyDamage.IsInfected() || this.BodyDamage.IsFakeInfected()) {
            stats.stress = (float)((double)stats.stress + ZomboidGlobals.StressFromBiteOrScratch * (double)GameTime.instance.getMultiplier() * (double)GameTime.instance.getDeltaMinutesPerDay());
         }

         if (this.Traits.Hemophobic.isSet()) {
            stats.stress = (float)((double)stats.stress + (double)this.getTotalBlood() * ZomboidGlobals.StressFromHemophobic * (double)(GameTime.instance.getMultiplier() / 0.8F) * (double)GameTime.instance.getDeltaMinutesPerDay());
         }

         if (this.Traits.Brooding.isSet()) {
            stats.Anger = (float)((double)stats.Anger - ZomboidGlobals.AngerDecrease * ZomboidGlobals.BroodingAngerDecreaseMultiplier * (double)GameTime.instance.getMultiplier() * (double)GameTime.instance.getDeltaMinutesPerDay());
         } else {
            stats.Anger = (float)((double)stats.Anger - ZomboidGlobals.AngerDecrease * (double)GameTime.instance.getMultiplier() * (double)GameTime.instance.getDeltaMinutesPerDay());
         }

         this.stats.Anger = PZMath.clamp(this.stats.Anger, 0.0F, 1.0F);
         this.stats.endurance = PZMath.clamp(this.stats.endurance, 0.0F, 1.0F);
         this.stats.hunger = PZMath.clamp(this.stats.hunger, 0.0F, 1.0F);
         this.stats.stress = PZMath.clamp(this.stats.stress, 0.0F, 1.0F);
         this.stats.fatigue = PZMath.clamp(this.stats.fatigue, 0.0F, 1.0F);
         tmpF = 1.0F - this.stats.getStress() - 0.5F;
         tmpF *= 1.0E-4F;
         if (tmpF > 0.0F) {
            tmpF += 0.5F;
         }

         stats.morale += tmpF;
         this.stats.morale = PZMath.clamp(this.stats.morale, 0.0F, 1.0F);
         this.stats.fitness = (float)this.getPerkLevel(Perks.Fitness) / 5.0F - 1.0F;
         if (this.stats.fitness > 1.0F) {
            this.stats.fitness = 1.0F;
         }

         if (this.stats.fitness < -1.0F) {
            this.stats.fitness = -1.0F;
         }
      }

      this.stats.fatigue = 0.0F;
      this.stats.thirst = 0.0F;
      this.stats.endurance = 1.0F;
   }

   protected void enterExitVehicle() {
      boolean b = this.PlayerIndex == 0 && GameKeyboard.isKeyDown(Core.getInstance().getKey("Interact"));
      if (b) {
         this.bUseVehicle = true;
         this.useVehicleDuration += GameTime.instance.getRealworldSecondsSinceLastUpdate();
      }

      if (!this.bUsedVehicle && this.bUseVehicle && (!b || this.useVehicleDuration > 0.5F)) {
         this.bUsedVehicle = true;
         if (this.getVehicle() != null) {
            LuaEventManager.triggerEvent("OnNPCUseVehicle", this, this.getVehicle(), this.useVehicleDuration > 0.5F);
         } else {
            for(int i = 0; i < this.getCell().vehicles.size(); ++i) {
               BaseVehicle baseVehicle = (BaseVehicle)this.getCell().vehicles.get(i);
               if (baseVehicle.getUseablePart(this) != null) {
                  LuaEventManager.triggerEvent("OnNPCUseVehicle", this, baseVehicle, this.useVehicleDuration > 0.5F);
                  break;
               }
            }
         }
      }

      if (!b) {
         this.bUseVehicle = false;
         this.bUsedVehicle = false;
         this.useVehicleDuration = 0.0F;
      }

   }

   public boolean CanSeeObject(IsoObject var1) {
      return LosUtil.lineClear(this.getCell(), (int)this.getX(), (int)this.getY(), (int)this.getZ(), (int)var1.getX(), (int)var1.getY(), (int)var1.getZ(), false) != TestResults.Blocked;
   }

   public boolean isPushableForSeparate() {
      return !this.isCurrentState(PlayerHitReactionState.instance()) && !this.isCurrentState(SwipeStatePlayer.instance()) && super.isPushableForSeparate();
   }

   public boolean isPushedByForSeparate(IsoMovingObject isoMovingObject) {
      return (this.isPlayerMoving() || !isoMovingObject.isZombie() || !((IsoZombie)isoMovingObject).isAttacking()) && this.isJustMoved() && super.isPushedByForSeparate(isoMovingObject);
   }

   public void startSendingUpdates(short var1, short var2) {
      zombie.characters.IsoNpcPlayer.NpcDamageUpdater var4;
      for(int var3 = 0; var3 < this.npcUpdaters.size(); ++var3) {
         var4 = (zombie.characters.IsoNpcPlayer.NpcDamageUpdater)this.npcUpdaters.get(var3);
         if (var4.npcOnlineId == var1 && var4.playerId == var2) {
            return;
         }
      }

      var4 = new zombie.characters.IsoNpcPlayer.NpcDamageUpdater();
      var4.npcOnlineId = var1;
      var4.playerId = var2;
      var4.bdLocal = this.getBodyDamage();
      var4.bdSent = new BodyDamage((IsoGameCharacter)null);
      this.npcUpdaters.add(var4);
   }

   public void stopSendingUpdates(short var1, short var2) {
      for(int var3 = 0; var3 < this.npcUpdaters.size(); ++var3) {
         zombie.characters.IsoNpcPlayer.NpcDamageUpdater var4 = (zombie.characters.IsoNpcPlayer.NpcDamageUpdater)this.npcUpdaters.get(var3);
         if (var4.npcOnlineId == var1 && var4.playerId == var2) {
            this.npcUpdaters.remove(var3);
            return;
         }
      }

   }

   public void checkAndAdjustToFreeSquare() {
      if (this.square != null) {
         if (!this.square.isNotBlocked(true)) {
            int x0 = this.square.x - 1;
            int y0 = this.square.y - 1;
            int x1 = this.square.x + 1;
            int y1 = this.square.y + 1;
            if (!GameClient.bClient && !GameServer.bServer) {
               x0 = (int)this.getX() - 1;
               y0 = (int)this.getY() - 1;
               x1 = (int)this.getX() + 1;
               y1 = (int)this.getY() + 1;
            }

            boolean found = false;
            IsoGridSquare foundSquare = null;

            for(int y = y0; y <= y1 && !found; ++y) {
               for(int x = x0; x <= x1 && !found; ++x) {
                  if (x != this.square.x || y != this.square.y) {
                     IsoGridSquare square = IsoWorld.instance.CurrentCell.getGridSquare(x, y, this.square.z);
                     if (square != null && square.isFree(true) && square.isOutside() == this.square.isOutside()) {
                        foundSquare = square;
                        found = true;
                        break;
                     }
                  }
               }
            }

            boolean enableUnstuckDebug = false;
            SandboxOption enableUnstuckDebugOption = SandboxOptions.instance.getOptionByName("KnoxEventExpanded.Debug_EnableNpcUnstuckPrint");
            if (enableUnstuckDebugOption instanceof BooleanSandboxOption) {
               BooleanSandboxOption bEnableUnstuckDebugDebugOption = (BooleanSandboxOption)enableUnstuckDebugOption;
               BooleanSandboxOption var10001 = (BooleanSandboxOption)enableUnstuckDebugOption;
               enableUnstuckDebug = bEnableUnstuckDebugDebugOption.getValue();
            }

            String var10000;
            if (foundSquare != null) {
               this.setX((float)foundSquare.x + 0.5F);
               this.setY((float)foundSquare.y + 0.5F);
               this.ensureOnTile();
               this.setLx((float)this.square.x + 0.5F);
               this.setLy((float)this.square.y + 0.5F);
               if (enableUnstuckDebug) {
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": Unstuck adjusted to " + this.getX() + "," + this.getY());
               }
            } else {
               WaypointHandler waypointHandler = WaypointHandler.getInstance();
               int sx = Float.valueOf(this.getX()).intValue();
               int sy = Float.valueOf(this.getY()).intValue();
               Vector2i npcVector = new Vector2i(sx, sy);
               Waypoint firstPoint = waypointHandler.findClosestWaypoint(npcVector);
               Vector2i unstuckPos = firstPoint.getPos();
               this.setX((float)unstuckPos.x + 0.5F);
               this.setY((float)unstuckPos.y + 0.5F);
               this.ensureOnTile();
               this.setLx((float)unstuckPos.x + 0.5F);
               this.setLy((float)unstuckPos.y + 0.5F);
               if (enableUnstuckDebug) {
                  var10000 = this.getUsername();
                  DebugLog.log(var10000 + ": Hard unstuck adjusted to " + this.getX() + "," + this.getY());
               }
            }

         }
      }
   }

   public String getPlayerRelation(IsoPlayer player) {
      HashMap<String, Integer> playerRelationships = this.relationships.getPlayerRelationships();
      return playerRelationships.containsKey(player.getUsername()) ? ((Integer)playerRelationships.get(player.getUsername())).toString() : null;
   }

   public InventoryItem getItemFromLua(String idStr) {
      try {
         long id = Long.parseLong(idStr);
         return this.getInventory().getItemById(id);
      } catch (NumberFormatException var4) {
         DebugLog.log("Got invalid long string: " + idStr);
         return null;
      }
   }

   public void removeItemWithIdFromInventory(String idStr) {
      long id = Long.parseLong(idStr);
      InventoryItem item = this.getInventory().getItemById(id);
      if (item != null) {
         DebugLog.log("Valid item with id " + idStr + ", removing from npc");
         this.getInventory().DoRemoveItem(item);
      }

   }
}
