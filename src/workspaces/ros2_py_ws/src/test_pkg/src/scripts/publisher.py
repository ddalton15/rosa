import rospy
import sys


def main():
    try:
        rospy.init_node("test_node", anonymous=True)

        rospy.loginfo("Rospy test node initialized successfully!")
        print(f"ROS_MASTER_URI: {rospy.get_param('/rosdistro', 'noetic')}")

    except Exception as e:
        rospy.logerr(f"Error initializing ROS node: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
